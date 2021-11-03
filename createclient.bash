#!/bin/bash

client=$1
password=$2

# create user
echo "Creating user"

useradd ${client} -p ${password} -m -d /home/${client}

mkdir /home/${client}/www

touch /home/${client}/www/index.php "${client}" 

chown ${client}:www-data -R /home/${client}

chmod 770 -R /home/${client}

echo "umask 007" >> sudo /home/${client}/.bashrc

# create nginx config

echo "creating nginx config"

echo "server {
    listen 80;
    listen [::]:80;

    server_name ${client}.ch www.${client}.ch;

    root /home/${client}/www;
    index index.html index.php;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args  =404;
    }

    location ~ \.php$ {
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass unix:/var/run/php/php7.4fpm-${client}.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
    }
}" >> /etc/nginx/sites-available/${client}

ln -s /etc/nginx/sites-available/${client} /etc/nginx/sites-enabled/

# create php config

echo "creating php config"

echo "[${client}]
user = ${client}
group = ${client}
listen = /var/run/php/php7.4fpm-${client}.sock
listen.owner = www-data
listen.group = www-data

pm = dynamic
pm.max_children = 64
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.process_idle_timeout = 10s" >> /etc/php/7.4/fpm/pool.d/${client}.conf

systemctl restart nginx
systemctl restart php7.4-fpm

#database
echo "Creating mariadb database"

query_mysql="CREATE DATABASE ${client};
GRANT ALL PRIVILEGES ON ${client}.* TO '${client}'@'%' IDENTIFIED BY '${password}';
FLUSH PRIVILEGES;"

mysql --execute="${mysql_query}"

