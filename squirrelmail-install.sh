#!/bin/sh

#public ipv4 and domain
read -p "What is the public ipv4 address of your server: 123.123.123.123 = an example: " ipvar
read -p "What is the registerd domain name? example.com = an example: " hostvar

#admin email
read -p "What will the server admin email be? admin@example.com = an example: " adminvar

#new user for webpage login gui
read -p "Enter the new user for the sign in page: " uservar
useradd $uservar
passwd $uservar

#display summary of entered information and prompt user to confirm
clear
echo -e "\e[1mSummary of entered information:\e[0m"
echo -e "\e[1mIPv4 address:\e[0m $ipvar"
echo -e "\e[1mDomain:\e[0m $hostvar"
echo -e "\e[1mAdmin email:\e[0m $adminvar"
echo -e "\e[1mWebpage GUI user:\e[0m $uservar"
read -p "Press enter to confirm or Ctrl+C to cancel."

#update package manager and upgrade installed packages
apt-get update && apt-get upgrade -y

#install MariaDB server and client
apt-get install mariadb-server mariadb-client -y

#start and enable MariaDB service
systemctl start mariadb
systemctl enable mariadb

#secure MariaDB installation
mysql_secure_installation

#install utility packages
apt-get install software-properties-common dialog bsdutils -y

#add required repositories
add-apt-repository ppa:ondrej/php -y
add-apt-repository ppa:ondrej/apache2 -y

#install required applications
apt install -y subversion apache2 build-essential php postfix dovecot-imapd dovecot-pop3d

#start and enable Apache web server
systemctl start apache2
systemctl enable apache2

#check for installation errors
if [ $? -ne 0 ]; then
echo "An error has occurred during the installation of one or more required packages."
exit 1
fi

#download Squirrelmail development version
svn checkout https://svn.code.sf.net/p/squirrelmail/code/trunk/squirrelmail
mv squirrelmail /var/www/html/

#set owner to www-data recursively
chown -R www-data:www-data /var/www/html/

#add user defined variables to config file
cat > /etc/apache2/sites-available/$hostvar.conf << EOF
<VirtualHost *:80>
ServerAdmin $adminvar
DocumentRoot /var/www/html/squirrelmail/
ServerName $hostvar
<Directory /var/www/html/squirrelmail/>
Options FollowSymLinks
AllowOverride All
Order allow,deny
allow from all
</Directory>
ErrorLog /var/log/apache2/$hostvar-error_log
CustomLog /var/log/apache2/$hostvar-access_log common
</VirtualHost>
EOF

#check for config file error
if [ $? -ne 0 ]; then
echo "An error has occurred with the config file in /etc/apache2/sites-available/$hostvar.conf"
exit 1
fi

#enable site and disable default site, update hosts file, and restart required services
a2ensite $hostvar.conf
a2dissite 000-default.conf
echo "$ipvar $hostvar" >> /etc/hosts
systemctl restart apache2 postfix dovecot

#check for service and application errors
if [ $? -ne 0 ]; then
echo "An error has occurred with one or more of the following services and applications: apache2, postfix, dovecot, a2dissite, a2ensite"
exit 1
fi

#create required directories and set permissions
mkdir -p /var/local/squirrelmail/data/
chown -R www-data:www-data /var/local/squirrelmail/data
mkdir -p /var/local/squirrelmail/attach/
chown -R www-data:www-data /var/local/squirrelmail/attach

#create new user defined variables and set permissions
mkdir /var/www/html/$uservar
usermod -m -d /var/www/html/$uservar $uservar
chown -R $uservar:$uservar /var/www/html/$uservar

#check for user creation and permission errors
if [ $? -ne 0 ]; then
echo "An error has occurred with the creation of $uservar dir and/or permissions."
exit 1
fi

#move default config to active config
cp /var/www/html/squirrelmail/config/config_default.php /var/www/html/squirrelmail/config/config.php

echo "---------------------------------------------------------------------------------------------------"
echo "Please test http://$hostvar or http://$ipvar to ensure everything is working properly."
echo "Remember to run 'perl /var/www/html/squirrelmail/config/conf.pl' to further configure Squirrelmail."
