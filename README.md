#	SharedHosting

## Autors
Théo Gautier

Cyril Goldenschue

## Context

This project is made in the context of the CLD1 module of the CPNV's ES developpement school. [The statment of the exercise](https://github.com/TGACPNV/CLD1-ConfigWebServer/blob/master/SharedHosting-statement.md) in french.

## Softwares versions

| name | version | 
| -------- | -------- |
| mariadb | 10.5.11 | 
| Debian | 11 | 
| php-fpm | 7.4 | 
| nginx | 1.18.0 |

# Isolating homes
To prevent other users to acces to other home:
```
sudo chmod o-rwx /home/*
```

This command has to be ran after every creation of users without the script.


## Secure SSH for users with sudo access
_This chapiter is optional._

SSH is installed by defalut on the system by the installer. There is nothing to do to install it. If not:
```
sudo apt install ssh
```

SSH access is restricted to user who avec a sudo access. They are not allowed to use simple username-password authentication, they have to have a couple of public-private keys configured to login.

To configure it we setup a rule int `/etc/ssh/sshd_config`:

```
Match Group sudo
 PasswordAuthentication no
Match all
```

Then, when a user have a couple of keys configued we can just add it to the sudo group with the command below.

`sudo usermod -a -G sudo USER`




## Installing Nginx

```sh
sudo apt update

sudo apt install nginx

# Enable the service at startup
sudo systemctl enable nginx

# Remove the default Nginx website
sudo rm /etc/nginx/sites-enabled/default
```


## Install PHP-FPM

```sh
sudo apt install php-fpm
```



## Install MariaDB
### Installation

```sh
sudo apt install mariadb-server
```

### config

Modifiy the file `/etc/mysql/mariadb.conf.d/50-server.cnf` and change the `bind-address` to this:
```
bind-address = 0.0.0.0
```

Edit `/etc/mysql/mariadb.cnf` and uncomment the following line:
```
port = 3306
```

restart mariadb service
```
sudo systemctl restart mariadb.service
```


# Customers isolation
Customer websites are isolated with the fact that we create homes with "others" rights to 0 and set umask of customers to 027 (see: client creation script).

# script of creation of users

[A script]() named `createClient.bash` is available on the repository to create clients.

This script has to be ran as root (with the root account or sudo).
