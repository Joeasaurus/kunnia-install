#!/usr/bin/env bash

puppetModules_toInstall=(
	"stankevich-python"
)

main() {
	printMessage "Configuring base system..."
	baseSystem
	printMessage "Installing Puppet modules..."
	puppetModules
	printMessage "Running Puppet manifests..."
	executeScripts .
	printMessage "Complete!"
}

printMessage() {
	echo "[KunInst] $1"
}

baseSystem() {
	printMessage " - Installing base packages..."
	yum -y install vim git
	printMessage " - Installing Puppet repository..."
	rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
	print printMessage " - Installing Puppet..."
	yum -y install puppet
	printMessage " - Done!"
}

puppetModules() {
	for module in ${puppetModules_toInstall[@]}; do
		puppet module install "$module"
	done
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
	printMessage " - Done!"
}

main