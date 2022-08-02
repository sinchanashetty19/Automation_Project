#Variables
myname="sinchana"
s3_bucket="upgrad-sinchana"
timestamp=$(date '+%d%m%Y-%H%M%S')

#updates the package information
sudo apt update -y

#Ensures that the HTTP Apache server is installed
dpkg -s apache2 &> /dev/null  
if [ $? -ne 0 ]
then
	echo "not installed"  
	sudo apt-get install apache2
else
	echo "installed"
fi

#Ensures that HTTP Apache server is running
if /etc/init.d/apache2 status > /dev/null
then 
	echo "Apache already running"
else 
	echo "Apache not running"
	sudo /etc/init.d/apache2 start
fi

#Ensures that HTTP Apache service is enabled
sudo systemctl is-enabled apache2
if [ $? -ne 0 ]
then 
	echo "Apache not enabled"
	sudo systemctl enable apache2
else 
	echo "Apache enabled"	
fi

#Archiving logs to S3
tar -cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log

# Installing awscli 
sudo apt update
sudo apt install awscli

aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

#Bookkeeping of the tar files uploaded to s3

tarfile=${myname}-httpd-logs-${timestamp}.tar
bookeeper='/var/www/html/inventory.html'
logtype='httpd-logs'
type='tar'
filesize=$(ls -l ${tarfile} | awk '{print $5}')

if [ -f "$bookeeper" ]
then
	echo "File exists."
       if [ -s $bookeeper ]
       then
		echo	$logtype		$timestamp		$type		$filesize >> $bookeeper
	else
		echo 	'LogType		Date Created		type		Size' >> $bookeeper
		echo	$logtype		$timestamp		$type		$filesize >> $bookeeper
	fi
else
	echo "File doesnt exist."
	touch $bookeeper
	echo 	'LogType		Date Created		type		Size' >> $bookeeper
	echo	$logtype		$timestamp		$type		$filesize >> $bookeeper
fi

#CRON job script

FILE='/etc/cron.d/automation'
if test -f "$FILE"
then
	echo "Cron job exists."
else
	sudo touch /etc/cron.d/automation
#CRON schedule to run everyday at 12:30 AM
	sudo echo "30 0 * * * /root/Automation_Project/automation.sh" > /etc/cron.d/automation
	sudo chmod 600 /etc/cron.d/automation
fi



