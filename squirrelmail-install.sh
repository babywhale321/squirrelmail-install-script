#!/bin/sh
#Made By: BabyWhale

#public ipv4 and domain
echo "What is the public ipv4 address of your server: 192.168.0.1 = an example: "
read -r ipvar

echo "What is the registerd domain name? google.com = an example: "
read -r hostvar

#admin email
echo "What will the server admin email be? admin@google.com = an example: "
read -r adminvar

#timezone selection
echo "What is your continent? America = an example: " 
read -r zone1var

echo "What is your city? New_York = an example: " 
read -r zone2var

echo ""
echo "Please verify that everything is correct then press enter"
echo "
ipv4: $ipvar
Domain: $hostvar
admin email: $adminvar
Timezone: $zone1var $zone2var "
read -r emptyvar

#Required repo and applications to be updated and installed
apt update ; apt upgrade -y ; apt-get install software-properties-common -y ; add-apt-repository ppa:ondrej/php -y ; add-apt-repository ppa:ondrej/apache2 -y ; apt install dialog -y ; apt install bsdutils -y || exit
apt install -y wget unzip apache2 build-essential mariadb-server mariadb-client php7.2 libapache2-mod-php7.2 php7.2-cli php7.2-fpm php7.2-cgi php7.2-bcmath php7.2-curl php7.2-gd php7.2-intl php7.2-json php7.2-mbstring php7.2-mysql php7.2-opcache php7.2-sqlite3 php7.2-xml php7.2-zip php7.2-snmp php7.2-imap php7.2-common php7.2-tidy php7.2-pgsql php7.2-ldap php7.2-soap php7.2-xsl php7.2-redis php7.2-xmlrpc postfix dovecot-imapd dovecot-pop3d || exit

#set timezone on apache
a2enmod rewrite expires ; sed -i "s/;date.timezone.*/date.timezone = $zone1var\/\$zone2var/" /etc/php/*/apache2/php.ini || exit
systemctl start apache2 mariadb ; systemctl enable apache2 mariadb ; mysql_secure_installation || exit

#Download and unzip squirrelmail
wget https://sourceforge.net/projects/squirrelmail/files/stable/1.4.22/squirrelmail-webmail-1.4.22.zip
unzip squirrelmail-webmail-1.4.22.zip

#Moving and adding permissions to website
mv squirrelmail-webmail-1.4.22 /var/www/html/
mv /var/www/html/squirrelmail-webmail-1.4.22/ /var/www/html/squirrelmail

#set permissions to data dir
chown -R www-data:www-data /var/www/html/ ; chmod -R 777 /var/www/html/

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
</VirtualHost>" > /etc/apache2/sites-available/$hostvar.conf

a2ensite $hostvar.conf ; a2dissite 000-default.conf  ; apache2ctl configtest ; echo "$ipvar $hostvar" >> /etc/hosts ; systemctl restart apache2 postfix dovecot || exit

#dir creation and permision set
mkdir -p /var/local/squirrelmail/data/ ; chmod -R 777 /var/local/squirrelmail/data

#new user for webpage login gui
echo "What is the new user for sign in page on website? bill = an example: "
read -r uservar
useradd $uservar
passwd $uservar

#new user defined variables creation and permissions
mkdir /var/www/html/$uservar ; usermod -m -d /var/www/html/$uservar $uservar ; chown -R $uservar:$uservar /var/www/html/$uservar

#moves the default into the active site
mv /var/www/html/squirrelmail/config/config_default.php config.php || exit


echo "Please test the web page to see if everything is working."
echo "Make sure to Run: perl /var/www/html/squirrelmail/config/conf.pl to further configure squirrelmail"
