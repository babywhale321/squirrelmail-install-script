#new user for webpage login gui
echo "What is the new user for sign in page on website? bill = an example: "
read -r uservar
useradd $uservar
passwd $uservar

#new user defined variables creation and permissions
mkdir /var/www/html/$uservar ; usermod -m -d /var/www/html/$uservar $uservar
chown -R $uservar:$uservar /var/www/html/$uservar ; chmod 777 -R /var/www/html/$uservar
