#!/bin/sh

#public ipv4 and domain
echo "What is the public ipv4 address of your server: 123.123.123.123 = an example: "
read ipvar

clear
echo "What is the registerd domain name? example.com = an example: "
read hostvar

clear
#admin email
echo "What will the server admin email be? admin@example.com = an example: "
read adminvar

clear
#new user for webpage login gui
echo "What will be the new user for the sign in page? bill = an example: "
read uservar
useradd $uservar
passwd $uservar

clear
echo " 
ipv4: $ipvar 
Domain: $hostvar
admin email: $adminvar 
Webpage GUI User: $uservar "
echo " "
echo "Please verify that all options are correct then press enter:"
read emptyvar

#Required repo and applications to be updated and installed
apt-get update ; apt-get upgrade -y ; apt-get install software-properties-common -y ; add-apt-repository ppa:ondrej/php -y ; add-apt-repository ppa:ondrej/apache2 -y ; apt install dialog bsdutils -y || echo "An error has accoured regarding the installation of 1 or more of these applications: software-properties-common, dialog, bsdutils" exit
apt install -y subversion apache2 build-essential mariadb-server mariadb-client php postfix dovecot-imapd dovecot-pop3d || echo "An error has accoured regarding the installation of 1 or more of these applications: subversion, apache2, build-essential, mariadb-server, mariadb-client, php, postfix, dovecot-imapd, dovecot-pop3d" exit
systemctl start apache2 mariadb ; systemctl enable apache2 mariadb ; mysql_secure_installation || echo "An error has accoured regarding starting 1 or more of these services: apache2, mariadb, mysql_secure_installation" exit

#Download squirrelmail dev version
svn checkout https://svn.code.sf.net/p/squirrelmail/code/trunk/squirrelmail
mv squirrelmail /var/www/html/

#owner set to www-data recursively
chown -R www-data:www-data /var/www/html/

#adds user defined variables to config files
echo "<VirtualHost *:80>
ServerAdmin $adminvar
DocumentRoot /var/www/html/squirrelmail/
ServerName $hostvar
<Directory  /var/www/html/squirrelmail/>
Options FollowSymLinks
AllowOverride All
Order allow,deny
allow from all
</Directory>
ErrorLog /var/log/apache2/$hostvar-error_log
CustomLog /var/log/apache2/$hostvar-access_log common
</VirtualHost>" > /etc/apache2/sites-available/$hostvar.conf || echo "An error has accoured with the config file in /etc/apache2/sites-available/$hostvar.conf" exit

a2ensite $hostvar.conf ; a2dissite 000-default.conf ; echo "$ipvar $hostvar" >> /etc/hosts ; systemctl restart apache2 postfix dovecot || echo "An error has accoured regarding services and applications of 1 or more of these listed: apache2, postfix, dovecot, a2dissite, a2ensite" exit

#dir creation and permision set
mkdir -p /var/local/squirrelmail/data/ ; chown -R www-data:www-data /var/local/squirrelmail/data
mkdir -p /var/local/squirrelmail/attach/ ; chown -R www-data:www-data /var/local/squirrelmail/attach

#new user defined variables creation and permissions
mkdir /var/www/html/$uservar ; usermod -m -d /var/www/html/$uservar $uservar ; chown -R $uservar:$uservar /var/www/html/$uservar || echo "An error has accoured with the creation of $uservar dir and or permissions" exit 

#moves the default config to active config
cp /var/www/html/squirrelmail/config/config_default.php /var/www/html/squirrelmail/config/config.php

echo "--------------------------------------------------------------------------------------------------"
echo "Please test the web page to see if everything is working."
echo "Make sure to Run: perl /var/www/html/squirrelmail/config/conf.pl to further configure squirrelmail"
