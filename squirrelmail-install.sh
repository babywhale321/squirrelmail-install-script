#!/bin/sh

#Start of log file to output potential errors
touch squirrelmail-install.log && chmod +rw squirrelmail-install.log
echo "The log file from this script can be viewed at squirrelmail-install.log in this current directory"
echo "Press enter to start the script or Ctrl+C to cancel." 
read pressstartvar
echo "Starting.." | tee -a squirrelmail-install.log

#public ipv4 and domain
echo "What is the public ipv4 address of your server: 123.123.123.123 = an example: " 
read ipvar
echo "What is the registerd domain name? example.com = an example: " 
read hostvar

#admin email
echo "What will the server admin email be? admin@example.com = an example: " 
read adminvar

#new user for webpage login gui
echo "Enter the new user for the sign in page: " 
read uservar
useradd $uservar
passwd $uservar

#display summary of entered information and prompt user to confirm
clear
echo "\e[1mSummary of entered information:\e[0m" | tee -a squirrelmail-install.log
echo "\e[1mIPv4 address:\e[0m $ipvar" | tee -a squirrelmail-install.log
echo "\e[1mDomain:\e[0m $hostvar" | tee -a squirrelmail-install.log
echo "\e[1mAdmin email:\e[0m $adminvar" | tee -a squirrelmail-install.log
echo "\e[1mWebpage GUI user:\e[0m $uservar" | tee -a squirrelmail-install.log
echo "Press enter to confirm or Ctrl+C to cancel."
read pressstartvar

#update package manager and upgrade installed packages
apt-get update && apt-get upgrade -y | tee -a squirrelmail-install.log

#update hosts file with ip and hostname
echo "$ipvar $hostvar" >> /etc/hosts | tee -a squirrelmail-install.log

#install MariaDB server and client
apt-get install mariadb-server mariadb-client -y | tee -a squirrelmail-install.log

#start and enable MariaDB service
systemctl start mariadb | tee -a squirrelmail-install.log
systemctl enable mariadb | tee -a squirrelmail-install.log

#secure MariaDB installation
mysql_secure_installation | tee -a squirrelmail-install.log

#install utility packages
apt-get install software-properties-common dialog bsdutils -y | tee -a squirrelmail-install.log

#add required repositories
add-apt-repository ppa:ondrej/php -y | tee -a squirrelmail-install.log
add-apt-repository ppa:ondrej/apache2 -y | tee -a squirrelmail-install.log
apt-get update && apt-get upgrade -y | tee -a squirrelmail-install.log

#install required applications
apt install -y subversion apache2 build-essential php postfix dovecot-imapd dovecot-pop3d | tee -a squirrelmail-install.log

#start and enable Apache web server
systemctl start apache2 | tee -a squirrelmail-install.log
systemctl enable apache2 | tee -a squirrelmail-install.log

#download Squirrelmail development version
svn checkout https://svn.code.sf.net/p/squirrelmail/code/trunk/squirrelmail | tee -a squirrelmail-install.log
mv squirrelmail /var/www/html/ | tee -a squirrelmail-install.log

#set owner to www-data recursively
chown -R www-data:www-data /var/www/html/ | tee -a squirrelmail-install.log

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

#enable site and disable default site, and restart required services
a2ensite $hostvar.conf | tee -a squirrelmail-install.log
a2dissite 000-default.conf | tee -a squirrelmail-install.log
systemctl restart apache2 postfix dovecot | tee -a squirrelmail-install.log

#create required directories and set permissions
mkdir -p /var/local/squirrelmail/data/ | tee -a squirrelmail-install.log
chown -R www-data:www-data /var/local/squirrelmail/data | tee -a squirrelmail-install.log
mkdir -p /var/local/squirrelmail/attach/ | tee -a squirrelmail-install.log
chown -R www-data:www-data /var/local/squirrelmail/attach | tee -a squirrelmail-install.log

#create new user defined variables and set permissions
mkdir /var/www/html/$uservar | tee -a squirrelmail-install.log
usermod -m -d /var/www/html/$uservar $uservar | tee -a squirrelmail-install.log
chown -R $uservar:$uservar /var/www/html/$uservar | tee -a squirrelmail-install.log

#move default config to active config
cp /var/www/html/squirrelmail/config/config_default.php /var/www/html/squirrelmail/config/config.php | tee -a squirrelmail-install.log

echo "---------------------------------------------------------------------------------------------------" | tee -a squirrelmail-install.log
echo "Please test http://$hostvar or http://$ipvar to ensure everything is working properly." | tee -a squirrelmail-install.log
echo "Remember to run 'perl /var/www/html/squirrelmail/config/conf.pl' to further configure Squirrelmail." | tee -a squirrelmail-install.log
