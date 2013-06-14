#!/usr/bin/env bash

#------------------------ Variable -----------------------------#
totalProcessor=$(nproc)
squidRunning=$(netstat -lpnt | grep squid | awk {'print $6'})
squidPort=$(netstat -lpnt | grep squid | awk {'print $4'} | awk -F ":" {'print $2'})

#------------------------ Function -----------------------------#

function header()
{
	echo -en "\e[01;32m############################################################\e[00m\n"
	echo -en "\e[01;32m#              SQUID LUSCHA HEAD INSTALLER                 #\e[00m\n"
	echo -en "\e[01;32m#                         ALPHA 1                          #\e[00m\n"
	echo -en "\e[01;32m#                                                          #\e[00m\n"
	echo -en "\e[01;32m#                   Brought to you by                      #\e[00m\n"
	echo -en "\e[01;32m#\e[00m                      \e[01;31mred-dragon\e[00m                          \e[01;32m#\e[00m\n"
	echo -en "\e[01;32m#                                                          #\e[00m\n"
	echo -en "\e[01;32m############################################################\e[00m\n"
}

function cin() {
	if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m" ; fi
	if [ "$1" == "info" ] ; then output="\e[01;33m[i]\e[00m" ; fi
	if [ "$1" == "warning" ] ; then output="\e[01;31m[w]\e[00m" ; fi
	if [ "$1" == "error" ] ; then output="\e[01;31m[e]\e[00m" ; fi
	output="$output $2"
	echo -en "$output"
}
 
function cout() {
	if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m" ; fi
	if [ "$1" == "info" ] ; then output="\e[01;33m[i]\e[00m" ; fi
	if [ "$1" == "warning" ] ; then output="\e[01;31m[w]\e[00m" ; fi
	if [ "$1" == "error" ] ; then output="\e[01;31m[e]\e[00m" ; fi
	output="$output $2"
	echo -e "$output"
}

function checkInternetConnection()
{
	cout action "Checking Internet Connection..."
	sleep 1
	command -v dig > /dev/null 2>&1
	if [[ $? = 0 ]]; then
		dig www.google.com +time=3 +tries=1 @8.8.8.8 > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			cout info "Good, you have Internet Connection..."
			squidURL="http://lusca-cache.googlecode.com/files/LUSCA_HEAD-r14809.tar.gz"			
		else
			cout error "You don't have Internet Connection!"
			sleep 1
			cout info "This script requiring Internet Connection!"
			sleep 1
			cout info "Make sure you have Internet Connection, then execute this script again"
			sleep 1
			cout action "Quiting..."
			sleep 2
			exit 1
		fi
	fi
}

function checkRoot()
{
	if [[ $(whoami) != "root" ]]; then
		cout error "You don't have root privilege!"
		cout action "Quiting..."
		sleep 2
		exit 1
	fi
}

function checkDependecies()
{
	cout action "Checking Dependencies..."
	sleep 1
	raw="squid squidclient squid-cgi gcc build-essential sharutils ccze libzip-dev automake1.9"
	dep=$(echo $raw | tr " " "\n")
	for dependencies in $dep; do
		cout action "Checking $dependencies"
		sleep 1
		if [[ $(dpkg -l | grep $dependencies | awk {'print $1'} | head -n 1) == "ii" ]]; then
			cout info "Found $dependencies."
		else
			cout warning "$dependencies not found!"
			askToInstallDependecies=true
			while [[ $askToInstallDependecies == "true" ]]; do
				cout info "Do you want to install missing dependencies? (Y/n)"
				read answerInstallDependencies
				if [[ $answerInstallDependencies == *[Yy]* ]] || [[ $answerInstallDependencies == "" ]]; then
					cout action "Installing $dependencies..."
					sleep 1
					apt-get install $dependencies --yes
					sleep 1
					cout info "Done..."
					sleep 1
					askToInstallDependecies=false
				elif [[ $answerInstallDependencies == *[Nn]* ]]; then
					cout info "Leave unresolve dependencies"
					sleep 1
					cout warning "You have unresolve dependencies, you may encounter some problems later"
					askToInstallDependecies=false
				else
					cout warning "Wrong input!"
				fi
			done
		fi
	done
}

function interrupt()
{
	echo -e "\n"
	cout error "CAUGHT INTERRUPT SIGNAL!!!"
	askToQuit=true
	while [[ $askToQuit == "true" ]]; do
		cin info "Do you really want to exit? (Y/n) "
		read answer
		if [[ $answer == *[Yy]* ]] || [[ $answer == "" ]]; then
			cout action "WTF!!!"
			sleep 1
			exit 0
		elif [[ $answer == *[Nn]* ]]; then
			cout action "Rock on..."
			askToQuit=false
		fi
	done
}

function setTerminal()
{
	cout action "Setup your default terminal..."
	sleep 1
	which terminator > /dev/null
	if [[ $(echo $?) -eq 0 ]]; then
		terminal=terminator
		cout info "Setup terminator as your terminal..."
	else
		cout error "Terminator not found! Finding another one..."
		sleep 1
		which gnome-terminal > /dev/null
		if [[ $(echo $?) -eq 0 ]]; then
			terminal=gnome-terminal
			cout info "Setup gnome-terminal as your terminal..."
		else
			cout error "gnome-terminal not found! Finding another one..."
			sleep 1
			which konsole > /dev/null
			if [[ $(echo $?) -eq 0 ]]; then
				terminal=konsole
				cout info "Setup konsole as your terminal..."
			else
				cout error "konsole not found! Finding another one..."
				which xterm > /dev/null
				if [[ $(echo $?)  -eq 0 ]]; then
					terminal=xterm
					cout info "Setup xterm as your terminal..."
				else
					cout error "xterm not found!"
					if [[ $terminal == "" ]]; then
						cout error "Looks like you don't have any terminal installed on your system. Make sure you have one of them, them execute this script again."
						cout action "Quiting..."
						sleep 2
						exit 1
					fi
				fi
			fi
		fi
	fi
}

function openTerminal()
{
	terminalCMD=$($terminal -e "$cmd")
}

function testTerminal()
{
	cout action "Testing your terminal..."
	sleep 1
	cmd="whoami; sleep 2"
	openTerminal > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		cout info "Looks good..."
		sleep 1
	else
		cout error "Looks not good... It's OK tho, but you may experience some problems on installation..."
	fi
}

function downloadSource()
{
	if [[ -f ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz ]]; then
		cout info "Source package is found. Will skip downloading source..."
		sleep 1
	else
		if [[ -d ~/Downloads ]]; then
			if [[ -d ~/Downloads/Apps ]]; then
				cout action "Downloading source, this may take several minutes. Depend on your internet connection..."
				sleep 1
				curl $squidURL -q -o ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz
				cout action "Done... Your squid source can be found on ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz"
				sleep 1
			else
				cout action "Creating 'Apps' directory in your 'Downloads' directory."
				sleep 1
				mkdir ~/Downloads/Apps
				cout action "Downloading source, this may take several minutes. Depend on your internet connection..."
				sleep 1
				curl $squidURL -q -o ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz
				cout action "Done... Your squid source can be found on ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz"
				sleep 1
			fi
		else
			cout action "Creating 'Downloads' directory in your home directory."
			mkdir ~/Downloads
			if [[ -d ~/Downloads/Apps ]]; then
				cout action "Downloading source, this may take several minutes. Depend on your internet connection..."
				sleep 1
				curl $squidURL -q -o ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz
				cout action "Done... Your squid source can be found on ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz"
				sleep 1
			else
				cout action "Creating 'Apps' directory in your 'Downloads' directory."
				sleep 1
				mkdir ~/Downloads/Apps
				cout action "Downloading source, this may take several minutes. Depend on your internet connection..."
				sleep 1
				curl $squidURL -q -o ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz
				cout action "Done... Your squid source can be found on ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz"
				sleep 1
			fi
		fi
	fi
}

function extractSource()
{
	cout action "Extracting package..."
	sleep 1
	if [[ -d ~/Downloads/Apps/LUSCA_HEAD-r14809 ]]; then
		cout info "Source directory is found! Will skip extracting source..."
		sleep 1
	else
		if [[ -f ~/Downloads/Apps/LUSCA_HEAD-r14809.tar.gz ]]; then
			cmd="cd ~/Downloads/Apps; tar -xvf LUSCA_HEAD-r14809.tar.gz; sleep 2"
			openTerminal > /dev/null 2>&1
			cout info "Done..."
			sleep 1
		else
			cout warning "Source package didn't found!"
			sleep 1
			cout action "Downloading Source..."
			sleep 1
			downloadSource
			extractSource
		fi
	fi
}

function configureSource()
{
	if [[ -d ~/Downloads/Apps/LUSCA_HEAD-r14809 ]]; then
		if [[ -f  ~/Downloads/Apps/LUSCA_HEAD-r14809/Makefile ]]; then
			if [[ $(head -n 1 ~/Downloads/Apps/LUSCA_HEAD-r14809/Makefile | awk {'print $2'}) == "red-dragon" ]]; then
				cout info "Source already configured... Skipping..."
			else
				cout action "Configuring source code..."
				sleep 1
				cmd="cd ~/Downloads/Apps/LUSCA_HEAD-r14809; ./configure '--prefix=/usr' '--exec_prefix=/usr' '--bindir=/usr/sbin' '--sbindir=/usr/sbin' '--libexecdir=/usr/lib/squid' '--sysconfdir=/etc/squid' '--localstatedir=/var/spool/squid' '--datadir=/usr/share/squid' '--enable-async-io=24' '--with-aufs-threads=24' '--with-pthreads' '--enable-storeio=coss,aufs' '--enable-linux-netfilter' '--enable-arp-acl' '--enable-epoll' '--with-aio' '--with-dl' '--enable-snmp' '--disable-delay-pools' '--enable-htcp' '--enable-cache-digests' '--disable-unlinkd' '--enable-large-cache-files' '--with-large-files' '--enable-err-languages=English' '--enable-default-err-language=English' '--with-maxfd=65536' '--enable-removal-policies=lru' '--enable-removal-policies=heap' 'CFLAGS=-march=core2 -O2 -pipe -fomit-frame-pointer'; sed -e '1i\# red-dragon\' -i Makefile; sleep 2"
				openTerminal > /dev/null 2>&1
				cout info "Done..."
			fi
		else
			cout action "Configuring source code..."
			sleep 1
			cmd="cd ~/Downloads/Apps/LUSCA_HEAD-r14809; ./configure '--prefix=/usr' '--exec_prefix=/usr' '--bindir=/usr/sbin' '--sbindir=/usr/sbin' '--libexecdir=/usr/lib/squid' '--sysconfdir=/etc/squid' '--localstatedir=/var/spool/squid' '--datadir=/usr/share/squid' '--enable-async-io=24' '--with-aufs-threads=24' '--with-pthreads' '--enable-storeio=coss,aufs' '--enable-linux-netfilter' '--enable-arp-acl' '--enable-epoll' '--with-aio' '--with-dl' '--enable-snmp' '--disable-delay-pools' '--enable-htcp' '--enable-cache-digests' '--disable-unlinkd' '--enable-large-cache-files' '--with-large-files' '--enable-err-languages=English' '--enable-default-err-language=English' '--with-maxfd=65536' '--enable-removal-policies=lru' '--enable-removal-policies=heap' 'CFLAGS=-march=core2 -O2 -pipe -fomit-frame-pointer'; sed -e '1i\# red-dragon\' -i Makefile; sleep 2"
			openTerminal > /dev/null 2>&1
			cout info "Done..."
		fi
	else
		extractSource
	fi
}

function  compileSource()
{
	cout action "Compiling Source..."
	sleep 1
	cmd="cd ~/Downloads/Apps/LUSCA_HEAD-r14809; make -j $totalProcessor; sleep 2"
	openTerminal > /dev/null 2>&1
	cout info "Done..."
	sleep 1
}

function installSquid()
{
	cout action "Installing squid..."
	sleep 1
	cmd="cd ~/Downloads/Apps/LUSCA_HEAD-r14809; make -j $totalProcessor install; sleep 2"
	openTerminal > /dev/null 2>&1
	cout info "Done..."
	sleep 1	
}

function configureSquid()
{
	cout action "Configuring squid... This may take several minutes..."
	sleep 1
	cp -rfv config/* /etc/squid/
	if [[ -d /squid ]]; then
		if [[ -d /squid/cache ]]; then
			cout info "Found directory /squid/cache"
			sleep 1
		else
			cout warning "Directory /squid/cache not found! Creating..."
			sleep 1
			mkdir /squid/cache
		fi
		if [[ -d /squid/log ]]; then
			cout info "Found directory /squid/log"
			sleep 1
			if [[ -f /squid/log/access.log ]]; then
				cout info "Found /squid/log/access.log"
				sleep 1
			else
				cout warning "File /squid/log/access.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/access.log
			fi
			if [[ -f /squid/log/error.log ]]; then
				cout info "Found /squid/log/error.log"
				sleep 1
			else
				cout warning "File /squid/log/error.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/error.log
			fi
			if [[ -f /squid/log/cache.log ]]; then
				cout info "Found /squid/log/cache.log"
				sleep 1
			else
				cout warning "File /squid/log/cache.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/cache.log
			fi
		else
			cout warning "Directory /squid/log not found! Creating..."
			sleep 1
			mkdir /squid/log
			if [[ -f /squid/log/access.log ]]; then
				cout info "Found /squid/log/access.log"
				sleep 1
			else
				cout warning "File /squid/log/access.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/access.log
			fi
			if [[ -f /squid/log/error.log ]]; then
				cout info "Found /squid/log/error.log"
				sleep 1
			else
				cout warning "File /squid/log/error.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/error.log
			fi
			if [[ -f /squid/log/cache.log ]]; then
				cout info "Found /squid/log/cache.log"
				sleep 1
			else
				cout warning "File /squid/log/cache.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/cache.log
			fi
		fi
		chmod -R 777 /squid/
	else
		mkdir /squid
		if [[ -d /squid/cache ]]; then
			cout info "Found directory /squid/cache"
			sleep 1
		else
			cout warning "Directory /squid/cache not found! Creating..."
			sleep 1
			mkdir /squid/cache
		fi
		if [[ -d /squid/log ]]; then
			cout info "Found directory /squid/log"
			sleep 1
			if [[ -f /squid/log/access.log ]]; then
				cout info "Found /squid/log/access.log"
				sleep 1
			else
				cout warning "File /squid/log/access.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/access.log
			fi
			if [[ -f /squid/log/error.log ]]; then
				cout info "Found /squid/log/error.log"
				sleep 1
			else
				cout warning "File /squid/log/error.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/error.log
			fi
			if [[ -f /squid/log/cache.log ]]; then
				cout info "Found /squid/log/cache.log"
				sleep 1
			else
				cout warning "File /squid/log/cache.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/cache.log
			fi
		else
			cout warning "Directory /squid/log not found! Creating..."
			sleep 1
			mkdir /squid/log
			if [[ -f /squid/log/access.log ]]; then
				cout info "Found /squid/log/access.log"
				sleep 1
			else
				cout warning "File /squid/log/access.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/access.log
			fi
			if [[ -f /squid/log/error.log ]]; then
				cout info "Found /squid/log/error.log"
				sleep 1
			else
				cout warning "File /squid/log/error.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/error.log
			fi
			if [[ -f /squid/log/cache.log ]]; then
				cout info "Found /squid/log/cache.log"
				sleep 1
			else
				cout warning "File /squid/log/cache.log not found!"
				sleep 1
				cout action "Creating..."
				touch /squid/log/cache.log
			fi
		fi
		chmod -R 777 /squid/
	fi
	askChangePort=true
	while [[ $askChangePort == "true" ]]; do
		cout info "Squid service, usually serve on port 3128. By default, this configuration will running squid on port 16791. Do you want to change it?"
		echo "1. Yes"
		echo "2. No, it's looks awesome"
		cin info "Your answer (1/2): "
		read answerChangePort
		if [[ $answerChangePort -eq 1 ]]; then
			askChangePort=false
			askPort=true
			while [[ $askPort == "true" ]]; do
				cin info "Please enter your desire port: "
				read port
				if [[ $port == *[a-z]* ]] || [[ $port == *[A-Z]* ]]; then
					cout warning "This is not a number!"
					sleep 2
				else
					askPort=false
					cout action "Will change squid port to $port"
					sed 's/http_port 16791 transparent/http_port $port transparent/g' -i /etc/squid/squid.conf
					sleep 1
					cout info "Done..."
					sleep 1
				fi
			done
		elif [[ $answerChangePort -eq 2 ]]; then
			askChangePort=false
			cout action "Rock on!"
			sleep 1
		else
			cout warning "This is not a valid anwser!"
			sleep 2
		fi
	done
	cout action "Parsing squid configuration..."
	sleep 1
	squid -k parse
	cout action "Building squid cache. This could take several minutes. Please wait, and have a coffee!"
	sleep 1
	squid -z
}

function finishing()
{
	cout action "I'm gonna check, is squid running or not."
	sleep 1
	if [[ $squidRunning == "LISTEN" ]]; then
		cout info "Squid already serving at port $squidPort"
	else
		cout info "Squid is not running, do you want to start it? (Y/n) "
		read answerRunSquid
		if [[ $answerRunSquid == *[Yy]* ]] || [[ $answerRunSquid == "" ]]; then
			cout action "Will run squid service..."
			sleep 1
			/etc/init.d/squid start
			sleep 1
			cout info "Squid serving at port $squidPort"
		fi
	fi
	cout info "All done, dude! Have a nice day :)"
	sleep 1
}

#------------------------ Main Program -----------------------------#
trap 'interrupt' INT
header
sleep 2
clear
checkInternetConnection
sleep 2
clear
checkRoot
sleep 2
clear
checkDependecies
sleep 2
clear
setTerminal
sleep 2
clear
testTerminal
sleep 2
clear
downloadSource
sleep 2
clear
extractSource
sleep 2
clear
configureSource
sleep 2
clear
compileSource
sleep 2
clear
installSquid
sleep 2
clear
configureSquid
sleep 2
clear
finishing
exit 0