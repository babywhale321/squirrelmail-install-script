#!/bin/sh

#Start of log file to output potential errors
touch squirrelmail-install.log && chmod +rw squirrelmail-install.log
echo "The log file from this script can be viewed at squirrelmail-install.log in this current directory"
read -p "Press enter to start the script or Ctrl+C to cancel."
echo "Starting.." | tee -a squirrelmail-install.log

#public ipv4 and domain
read -p "What is the public ipv4 address of your server: 123.123.123.123 = an example: " ipvar
read -p "What is the registerd domain name? example.com = an example: " hostvar

#admin email
read -p "What will the server admin email be? admin@example.com = an example: " adminvar

#new user for webpage login gui
read -p "Enter the new user for the sign in page: " uservar
useradd $uservar
passwd $uservar

#check for errors
if [ $? -ne 0 ]; then
echo "An error has occurred during creating the user $uservar"
exit 1
fi

#display summary of entered information and prompt user to confirm
clear
echo -e "\e[1mSummary of entered information:\e[0m" | tee -a squirrelmail-install.log
echo -e "\e[1mIPv4 address:\e[0m $ipvar" | tee -a squirrelmail-install.log
echo -e "\e[1mDomain:\e[0m $hostvar" | tee -a squirrelmail-install.log
echo -e "\e[1mAdmin email:\e[0m $adminvar" | tee -a squirrelmail-install.log
echo -e "\e[1mWebpage GUI user:\e[0m $uservar" | tee -a squirrelmail-install.log
read -p "Press enter to confirm or Ctrl+C to cancel."

#update package manager and upgrade installed packages
apt-get update && apt-get upgrade -y | tee -a squirrelmail-install.log

#install MariaDB server and client
apt-get install mariadb-server mariadb-client -y | tee -a squirrelmail-install.log

#check for errors
if [ $? -ne 0 ]; then
echo "An error has occurred during installing mariadb-server mariadb-client"
exit 1
fi

#start and enable MariaDB service
systemctl start mariadb | tee -a squirrelmail-install.log
systemctl enable mariadb | tee -a squirrelmail-install.log

#check for errors
if [ $? -ne 0 ]; then
echo "An error has occurred during starting and enabling mariadb"
exit 1
fi

#secure MariaDB installation
mysql_secure_installation | tee -a squirrelmail-install.log

#check for errors
if [ $? -ne 0 ]; then
echo "An error has occurred during mysql_secure_installation prompts"
exit 1
fi

#install utility packages
apt-get install software-properties-common dialog bsdutils -y | tee -a squirrelmail-install.log

#check for errors
if [ $? -ne 0 ]; then
echo "An error has occurred during installing one or more of these packages: software-properties-common dialog bsdutils"
exit 1
fi

#add required repositories
add-apt-repository ppa:ondrej/php -y | tee -a squirrelmail-install.log
add-apt-repository ppa:ondrej/apache2 -y | tee -a squirrelmail-install.log

#check for errors
if [ $? -ne 0 ]; then
echo "An error has occurred during adding these repositories ppa:ondrej/php ppa:ondrej/apache2"
exit 1
fi

#install required applications
apt install -y subversion apache2 build-essential php postfix dovecot-imapd dovecot-pop3d | tee -a squirrelmail-install.log

#check for errors
if [ $? -ne 0 ]; then
echo "An error has occurred during installing these applications: subversion apache2 build-essential php postfix dovecot-imapd dovecot-pop3d"
exit 1
fi

#start and enable Apache web server
systemctl start apache2 | tee -a squirrelmail-install.log
systemctl enable apache2 | tee -a squirrelmail-install.log

#check for errors
if [ $? -ne 0 ]; then
echo "An error has occurred during starting and enabling apache2"
exit 1
fi

#download Squirrelmail development version
svn checkout https://svn.code.sf.net/p/squirrelmail/code/trunk/squirrelmail | tee -a squirrelmail-install.log
mv squirrelmail /var/www/html/ | tee -a squirrelmail-install.log

#check for errors
if [ $? -ne 0 ]; then
echo "An error has occurred during downloading Squirrelmail development version"
exit 1
fi

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

#check for config file error
if [ $? -ne 0 ]; then
echo "An error has occurred with the config file in /etc/apache2/sites-available/$hostvar.conf"
exit 1
fi

#enable site and disable default site, update hosts file, and restart required services
a2ensite $hostvar.conf | tee -a squirrelmail-install.log
a2dissite 000-default.conf | tee -a squirrelmail-install.log
echo "$ipvar $hostvar" >> /etc/hosts | tee -a squirrelmail-install.log
systemctl restart apache2 postfix dovecot | tee -a squirrelmail-install.log

#check for service and application errors
if [ $? -ne 0 ]; then
echo "An error has occurred with one or more of the following services and applications: apache2, postfix, dovecot, a2dissite, a2ensite"
exit 1
fi

#create required directories and set permissions
mkdir -p /var/local/squirrelmail/data/ | tee -a squirrelmail-install.log
chown -R www-data:www-data /var/local/squirrelmail/data | tee -a squirrelmail-install.log
mkdir -p /var/local/squirrelmail/attach/ | tee -a squirrelmail-install.log
chown -R www-data:www-data /var/local/squirrelmail/attach | tee -a squirrelmail-install.log

#create new user defined variables and set permissions
mkdir /var/www/html/$uservar | tee -a squirrelmail-install.log
usermod -m -d /var/www/html/$uservar $uservar | tee -a squirrelmail-install.log
chown -R $uservar:$uservar /var/www/html/$uservar | tee -a squirrelmail-install.log

#check for user creation and permission errors
if [ $? -ne 0 ]; then
echo "An error has occurred with the creation of $uservar dir and/or permissions."
exit 1
fi

#move default config to active config
cp /var/www/html/squirrelmail/config/config_default.php /var/www/html/squirrelmail/config/config.php | tee -a squirrelmail-install.log

echo "---------------------------------------------------------------------------------------------------" | tee -a squirrelmail-install.log
echo "Please test http://$hostvar or http://$ipvar to ensure everything is working properly." | tee -a squirrelmail-install.log
echo "Remember to run 'perl /var/www/html/squirrelmail/config/conf.pl' to further configure Squirrelmail." | tee -a squirrelmail-install.log
