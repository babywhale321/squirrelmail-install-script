#!/bin/sh
#Made By: BabyWhale

#public ipv4 and domain
echo "What is the public ipv4 address of your server: 123.123.123.123 = an example: "
read -r ipvar

echo "What is the registerd domain name? example.com = an example: "
read -r hostvar

#admin email
echo "What will the server admin email be? admin@example.com = an example: "
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
apt install -y subversion apache2 build-essential mariadb-server mariadb-client php postfix dovecot-imapd dovecot-pop3d || exit

#set timezone on apache
a2enmod rewrite expires ; sed -i "s/;date.timezone.*/date.timezone = $zone1var\/\$zone2var/" /etc/php/*/apache2/php.ini || exit
systemctl start apache2 mariadb ; systemctl enable apache2 mariadb ; mysql_secure_installation || exit

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
</VirtualHost>" > /etc/apache2/sites-available/$hostvar.conf

a2ensite $hostvar.conf ; a2dissite 000-default.conf  ; apache2ctl configtest ; echo "$ipvar $hostvar" >> /etc/hosts ; systemctl restart apache2 postfix dovecot || exit

#dir creation and permision set
mkdir -p /var/local/squirrelmail/data/ ; chmod -R 777 /var/local/squirrelmail/data

#new user for webpage login gui
echo ""
echo "What is the new user for sign in page on website? bill = an example: "
read -r uservar
useradd $uservar
passwd $uservar

#new user defined variables creation and permissions
mkdir /var/www/html/$uservar ; usermod -m -d /var/www/html/$uservar $uservar ; chown -R $uservar:$uservar /var/www/html/$uservar

#moves the default config to active config
cd /var/www/html ; svn update squirrelmail ; cd squirrelmail/config/ ; cp config_default.php config.php || exit

echo "Please test the web page to see if everything is working."
echo "Make sure to Run: perl /var/www/html/squirrelmail/config/conf.pl to further configure squirrelmail"
