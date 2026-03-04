#!/bin/bash
set -euxo pipefail

# Update system
apt-get update -y

# Install Apache, PHP, MySQL client, Git
apt-get install -y apache2 php libapache2-mod-php mysql-client git

# Health check endpoint
echo "OK" > /var/www/html/health

# PHP test page
cat > /var/www/html/index.php <<'EOF'
<?php
echo "App Tier Running\n";

$db_host = getenv('DB_HOST');
$db_user = getenv('DB_USER');
$db_pass = getenv('DB_PASS');
$db_name = getenv('DB_NAME');

if ($db_host) {
    $conn = @new mysqli($db_host,$db_user,$db_pass,$db_name);
    if ($conn->connect_error) {
        echo "DB connection failed\n";
    } else {
        echo "DB connection success\n";
    }
}
?>
EOF

systemctl enable apache2
systemctl restart apache2

