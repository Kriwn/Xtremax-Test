#!/bin/bash
# Terraform template: region, db_name, db_host and db_secret_arn are filled in
# by templatefile() in main.tf.
set -euo pipefail

# 1. Install Apache + PHP (Amazon Linux 2023), and tar to unpack WordPress
dnf install -y httpd php php-fpm php-mysqlnd php-gd php-mbstring php-xml tar

# 2. Install WordPress
curl -fsSL https://wordpress.org/latest.tar.gz -o /tmp/wordpress.tar.gz
tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1

# 3. Save the DB login from Secrets Manager (the instance role allows this)
mkdir -p /etc/wordpress
aws secretsmanager get-secret-value \
  --region "${region}" \
  --secret-id "${db_secret_arn}" \
  --query SecretString --output text > /etc/wordpress/db.json
chown root:apache /etc/wordpress/db.json
chmod 640 /etc/wordpress/db.json

# 4. Write wp-config.php (same on every instance, so no web installer per server)
#    No AUTH_KEY/salts: WordPress then keeps them in the database,
#    so all instances share them and logins work behind the ALB.
cat > /var/www/html/wp-config.php <<'EOF'
<?php
$db = json_decode(file_get_contents('/etc/wordpress/db.json'), true);

define('DB_NAME', '${db_name}');
define('DB_USER', $db['username']);
define('DB_PASSWORD', $db['password']);
define('DB_HOST', '${db_host}');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

$table_prefix = 'wp_';

// HTTPS ends at the ALB: trust its header so WordPress uses https URLs
if (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}
require_once ABSPATH . 'wp-settings.php';
EOF

chown -R apache:apache /var/www/html

# 5. Start the web server
systemctl enable --now php-fpm httpd
