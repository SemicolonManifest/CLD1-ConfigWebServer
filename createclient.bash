#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]
  then echo "Error: Please run as root. Aborted."
  exit
fi


clientok=0
passwordok=0



while [[ $clientok -eq 0 ]]; do
    echo -n "Username: "
    read -r client
    if [[ -n $client ]]; then
            clientok=1
    else
            echo -e "\nPlease enter a username!"
    fi
done

while [[ $passwordok -eq 0 ]]; do
    # from https://stackoverflow.com/questions/2654009/how-to-make-bash-script-ask-for-a-password
    echo -n "Password: "
    stty_orig=$(stty -g) # save original terminal setting.
    stty -echo           # turn-off echoing.
    read -r password  # read the password
    stty "$stty_orig"    # restore terminal setting.

    if [[ -n $password ]]; then
        firstpassSuccess=1
        else
        echo -e "\nPlease enter a password!"
    fi

    if [[ $firstpassSuccess -eq 1 ]]; then
        echo -ne "\nConfirm Password: "
        stty_orig=$(stty -g) # save original terminal setting.
        stty -echo           # turn-off echoing.
        read -r confirmpassword  # read the password
        stty "$stty_orig"    # restore terminal setting.

        if [[ "$password" == "$confirmpassword" ]]; then
        passwordok=1
        else echo -e "\nPasswords did not match"
        firstpassSuccess=0
        fi
    fi
done


# create user
echo -e "\n\nCreating user"

useradd ${client} -p $(openssl passwd -crypt ${password}) -m -d "/home/${client}" -s /bin/bash

mkdir /home/${client}/www

echo "${client}" >> /home/${client}/www/index.php

chown ${client}:www-data -R /home/${client}

chmod 750 -R /home/${client}

echo "umask 007" >> /home/${client}/.bashrc

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

echo -e "creating php config"

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
echo -e "Creating mariadb database"

query_mysql="CREATE DATABASE ${client};
GRANT ALL PRIVILEGES ON ${client}.* TO '${client}'@'%' IDENTIFIED BY '${password}';
FLUSH PRIVILEGES;"

mysql --execute="${query_mysql}"