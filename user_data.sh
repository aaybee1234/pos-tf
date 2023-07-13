#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

yum install -y php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc

cd /var/www/html
wget https://codeload.github.com/deenseth/PHP-Point-Of-Sale/zip/refs/heads/master -O pos.zip
unzip pos.zip
mv PHP-Point-Of-Sale-master php

chown -R apache:apache /var/www/html/php
chmod -R 755 /var/www/html/php

cat << EOT > /var/www/html/php/application/config/database.php
<?php
\$active_group = "default";
\$active_record = TRUE;

\$db['default']['hostname'] = "${aws_instance.data_server.private_ip}"; // IP address of the database server
\$db['default']['username'] = "php_pos_user";
\$db['default']['password'] = "password";
\$db['default']['database'] = "php_point_of_sale";
\$db['default']['dbdriver'] = "mysqli";
\$db['default']['dbprefix'] = "phppos_";
\$db['default']['pconnect'] = FALSE;
\$db['default']['db_debug'] = FALSE;
\$db['default']['cache_on'] = FALSE;
\$db['default']['cachedir'] = "";
\$db['default']['char_set'] = "utf8";
\$db['default']['dbcollat'] = "utf8_general_ci";
EOT

systemctl restart httpd
