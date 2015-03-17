#!/usr/bin/env bash

puppetModules_toInstall=(
	"stahnma-epel"
	"yguenane-repoforge"
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
	yum groups mark convert
	yum -d 0 -e 0 -y groupinstall "Development tools"
	yum -d 0 -e 0 -y install vim git wget

	printMessage " - Installing Puppet repository..."
	rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
	print printMessage " - Installing Puppet..."
	yum -d 0 -e 0 -y install puppet

	printMessage " - Installing dev tools..."
	installPython

	printMessage " - Done!"
}

installPython() {
	# Python 3.3.5:
	if [[ -z "$(command -v python3.3)" ]]; then
		wget http://python.org/ftp/python/3.3.5/Python-3.3.5.tar.xz
		tar xf Python-3.3.5.tar.xz
		pushd Python-3.3.5
		./configure --prefix=/usr/local --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
		make && make altinstall
		popd && rm -rf ./Python*
	fi
}

puppetModules() {
	for module in ${puppetModules_toInstall[@]}; do
		printMessage " - Installing $module"
		puppet module install "$module"
	done
	printMessage " - Done!"
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