#!/usr/bin/env bash

#------------------------ Variable -----------------------------#

#------------------------ Function -----------------------------#

cin() {
	if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m" ; fi
	if [ "$1" == "info" ] ; then output="\e[01;33m[i]\e[00m" ; fi
	if [ "$1" == "warning" ] ; then output="\e[01;31m[w]\e[00m" ; fi
	if [ "$1" == "error" ] ; then output="\e[01;31m[e]\e[00m" ; fi
	output="$output $2"
	echo -en "$output"
}
 
cout() {
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
	cmd="whoami; sleep 3"
	openTerminal > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		cout info "Looks good..."
		sleep 1
	else
		cout error "Looks not good... It's OK tho, but you may experience some problems on installation..."
	fi
}

#------------------------ Main Program -----------------------------#
trap 'interrupt' INT
checkInternetConnection
checkRoot
checkDependecies
setTerminal
testTerminal