#!/bin/bash
##################################################################
# HiPi.io UPS hat installation script for systemd
# https://github.com/hipi-io/ups-hat
##################################################################

# Install required packages onto your pi
echo "...Installing required packages"
sudo apt update
sudo apt install -y git
sudo apt install -y gpiod

# Clone the shell script from the HiPi-io ups-hat repository
git clone https://github.com/hipi-io/ups-hat.git  # Production repo
#git clone https://github.com/Martin-HiPi/ups-hat.git  # Staging repo

# Navigate into the UPS script folder
cd ups-hat
echo "...Source folder: $( pwd )"

# Stop and disable the existing service
echo "...Removing old scripts"
sudo systemctl disable ups
sudo systemctl disable hipi-io-ups-hat.service
sudo systemctl stop ups
sudo systemctl stop hipi-io-ups-hat.service

# Remove previous SysV copies of the service
if [ -e /etc/init.d/ups.sh ]; then 
	echo "___Shutting down the UPS hat service..."
	touch /tmp/ups-hat.exit

	sleep 5
	
	if [ -e /tmp/ups-hat.quit ]; then
		echo "...Service for UPS hat stopped!"
		sudo rm -v /tmp/ups-hat.quit
	else
		echo "...Force-stopping the service for UPS hat!"
		sudo killall "ups.sh"
		sudo rm -v /tmp/ups-hat.*
	fi

	echo "___Removing SystemV service..."
	sudo update-rc.d ups.sh disable
	sudo rm -v /etc/init.d/ups.sh
	sudo update-rc.d -f ups.sh remove
	echo "___SystemV UPS hat service removed."
	echo
	echo "*** REBOOT RECOMMENDED!!! ***"
	echo
fi

# clean up old files
echo "...Removing old files"
sudo rm -v /etc/systemd/system/hipi-io-ups-hat.service
sudo rm -v /usr/local/sbin/hipi-io-ups-hat-service
sudo rm -v /usr/local/sbin/hipi-io-ups-hat-gpio-set
sudo rm -v /usr/local/sbin/hipi-io-ups-hat-gpio-reset


# copy the hipi-io-ups-hat.service unit file to the /etc/systemd/system directory to run the script on startup
# Should we use /usr/local/lib/systemd/system, "for use by the system administrator when installing software locally"?
echo "...Copying new files"
sudo cp -v systemd/hipi-io-ups-hat.service /etc/systemd/system/hipi-io-ups-hat.service
sudo chown -v root:root /etc/systemd/system/hipi-io-ups-hat.service

# copy the UPS hat script to /usr/local/sbin (Tertiary hierarchy for local data, specific to this host.)
sudo cp -v scripts/Bullseye/ups-gpiod.sh /usr/local/sbin/hipi-io-ups-hat-service
#sudo cp -v scripts/ups-set.py /usr/local/sbin/hipi-io-ups-hat-gpio-set
#sudo cp -v scripts/ups-reset.py /usr/local/sbin/hipi-io-ups-hat-gpio-reset

# Make the service scripts executable
sudo chmod -v +x /usr/local/sbin/hipi-io-ups-hat-service
#sudo chmod -v +x scripts/gpiod/ups-gpiod.sh
#sudo chmod -v +x /usr/local/sbin/hipi-io-ups-hat-gpio-set
#sudo chmod -v +x /usr/local/sbin/hipi-io-ups-hat-gpio-reset

#sudo cp -v scripts/gpiod/ups-gpiod.sh /usr/local/sbin/hipi-io-ups-hat-service
sudo chown -v root:root /usr/local/sbin/hipi-io-ups-hat-*

# reload daemons
sudo systemctl daemon-reload

echo "...Starting UPS hat service..."
sudo systemctl enable hipi-io-ups-hat.service --no-pager
sudo systemctl start hipi-io-ups-hat.service --no-pager

echo "---Service hipi-io-ups-hat.service should be active!"
#ps -aux | grep "hipi-io-ups-hat-service"
sudo systemctl status hipi-io-ups-hat.service --no-pager
