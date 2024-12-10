#!/bin/bash
#!/bin/bash                                                                                  
# RRRRRRRRRRR   RRRRRRRRRR   6666666666      444444
# RR        RR  RR       RR  66      66     44   44
# RR        RR  RR       RR  66            44    44
# RR        RR  RR       RR  66           44     44
# RR        RR  RR       RR  66          44      44
# RRRRRRRRRR    RRRRRRRRR    66666666    4444444444
# RR       RR   RR      RR   66      66          44
# RR        RR  RR       RR  66      66          44
# RR        RR  RR       RR  66      66          44
# RR        RR  RR       RR  66      66          44
# RR        RR  RR       RR  6666666666          44
# ====================================#
#
#  PHPipam  data: 22/09/2023
#  
# ====================================#
#  
#  autores: Rafael Burger de Oliveira
#           Thais Cristina Murça
#
# ====================================#
#  
#  Instalando PHPIpam
#
# ====================================#
#
# Requerimentos:
# CPU: 4vCPU/8vCPU
# Memoria RAM: 8GB
# HDD/SSD: 200GB
# 
# ====================================#

# Criaçao de usuario
echo "Insira o nome de usuario:"
read user
useradd $user
echo "Insira a senha para o usuario $user: "
read senha

mkdir /home/$user

if [ "$senha" == "" ]
then
    echo "Insira uma senha válida..."
    echo "Senha para $user: "
    read senha
else
    echo "$user":"$senha" | chpasswd
fi

# Correçao de Repositorio
export PATH=$PATH:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
echo "PATH="/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/games:/usr/local/games"" >> /etc/environment

# Atualizando
apt update; apt upgrade -y
apt install -y vim nano wget net-tools snmpd 

# Instala PHP
apt install -y apache2 php php-cli libapache2-mod-php php-curl php-mysql php-curl php-gd php-intl php-pear php-imap php-apcu php-pspell php-tidy php-xmlrpc php-mbstring php-gmp php-json php-xml php-ldap php-common php-snmp php-fpm

# Arrumando Localidade
sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/' /etc/php/7.4/fpm/php.ini
systemctl restart php7.4-fpm.service

# Instalando MariaDB
apt install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb
echo -e "y\nadmin\nadmin\ny\ny\ny\ny" | mysql_secure_installation

#Inserindo no banco
# Configurando o Banco de dados
echo "Insira a senha para o usuario root (MySQL):"
read senhasql

if [ "$senhasql" == "" ]
then
    echo "Insira novamente a senha."
    read senhasql
    mysql -uroot -p$senhasql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$senhasql';"
    mysql -uroot -p$senhasql -e "create database phpipam character set utf8mb4 collate utf8mb4_bin;"
    mysql -uroot -p$senhasql -e "create user phpipam@localhost identified by '$senhasql';"
    mysql -uroot -p$senhasql -e "grant all privileges on phpipam.* to phpipam@localhost;"
    mysql -uroot -p$senhasql -e "flush privileges"
else
    mysql -uroot -p$senhasql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$senhasql';"
    mysql -uroot -p$senhasql -e "create database phpipam character set utf8mb4 collate utf8mb4_bin;"
    mysql -uroot -p$senhasql -e "create user phpipam@localhost identified by '$senhasql';"
    mysql -uroot -p$senhasql -e "grant all privileges on phpipam.* to phpipam@localhost;"
    mysql -uroot -p$senhasql -e "flush privileges"
fi

#Instala o repositorio
apt install git -y
git clone --recursive https://github.com/phpipam/phpipam.git /var/www/html/phpipam

cd /var/www/html/phpipam
cp config.dist.php config.php

sed -i "s/\$db\['host'\] = '127.0.0.1';/\$db\['host'\] = 'localhost';/" /var/www/html/phpipam/config.php
sed -i "s/\$db\['pass'\] = 'phpipamadmin';/\$db\['pass'\] = '$senhasql';/" /var/www/html/phpipam/config.php

cd /etc/apache2/sites-enabled/
mv 000-default.conf 000-default.conf.bkp

echo "<VirtualHost *:80>
    ServerAdmin webmaster@techviewleo.com
    DocumentRoot "/var/www/html/phpipam"
    ServerName ipam.techviewleo.com
    ServerAlias www.ipam.techviewleo.com
    <Directory "/var/www/html/phpipam">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "/var/log/apache2/phpipam-error_log"
    CustomLog "/var/log/apache2/phpipam-access_log" combined
</VirtualHost>" >> 000-default.conf

chown -R www-data:www-data /var/www/html/

#Verifica a sintaxe
apachectl -t
#Roda comando para atualizar apache
a2enmod rewrite
#Reinicia o serviço
systemctl restart apache2

# Configurando SSH
sed -i 's/#Port 22/Port 2210/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

mysql -u root -p$senhasql phpipam < /var/www/html/phpipam/db/SCHEMA.sql

echo "Acesso Web
user: Admin
password: ipamadmin"
