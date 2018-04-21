#!/bin/bash

# Copyright 2017-2018 Tim Scharner (https://timscha.io)
# Version 0.5.0-dev

#########################################################
# This script is intended to be run like this:
#
#   curl https://timscha.io/setup.sh | sudo bash
#
#########################################################

## Detect distro version
if [ -e /etc/redhat-release ]; then
     DISTRO="centos"
elif [ -e /etc/debian_version ]; then
     DISTRO="debian"
fi

if ! [ $DISTRO = "debian" ] || ! [ $DISTRO = "debian" ] ||; then
	echo "This script runs on Debian and CentOS only. Exit now."
	exit
fi

# Are we running as root?
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root. Exit now."
	exit
fi

# Clone the Mail-in-a-Box repository if it doesn't exist.
if [ ! -d $HOME/SLEMP ]; then
	if [ ! -f /usr/bin/git ]; then
		echo Installing git . . .
		apt-get -q -q update
		DEBIAN_FRONTEND=noninteractive apt-get -q -q install -y git < /dev/null
		echo
	fi

	echo Downloading SLEMP files . . .
	git clone \
		https://github.com/timscha/SLEMP.git \
		$HOME/SLEMP \
		< /dev/null 2> /dev/null
	echo
fi

# Change directory to it and start the setup
cd $HOME/SLEMP
./install.sh
