#!/usr/bin/env bash

main() {
	printMessage "Configuring base system..."
	baseSystem
	printMessage "Running Puppet manifests..."
	executeScripts .
	printMessage "Complete."
}

printMessage() {
	echo "[KunInst] $1"
}

baseSystem() {
	printMessage " - Installing Puppet repository..."
	rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
	printMessage " - Done"
}

executeScripts() {
	local dir="$1"
	for puppetFile in $(ls $dir); do
		printMessage " - Applying $puppetFile..."
		puppet apply "$puppetFile"
		if [[ $? -ne 0 ]]; then
			printMessage "There was an error, exiting!"
			exit 1
		fi
	done
	printMessage " - Done"
}

main