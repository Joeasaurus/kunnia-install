#!/usr/bin/env bash

export BB_LOG_USE_COLOR=true
export BB_LOG_LEVEL=INFO

puppetModules_toInstall=(
	"stahnma-epel"
	"yguenane-repoforge"
)

main() {
	bb-log-info "Configuring base system..."
	baseSystem
	bb-log-info "Installing Puppet modules..."
	puppetModules
	bb-log-info "Running Puppet manifests..."
	executeScripts puppet
	bb-exit 0 "Complete!"
}

installBashBooster() {
	wget https://bitbucket.org/kr41/bash-booster/downloads/bashbooster-0.3beta.zip
	unzip bashbooster-0.3beta.zip
	pushd bashbooster-0.3beta
	./install.sh
	popd
	rm -rf ./bashbooster*
}

baseSystem() {
	bb-log-debug " - Preparing Yum..."
	yum groups mark convert

	bb-log-debug " - Installing base packages..."
	yum -d 0 -e 0 -y groupinstall "Development tools"
	yum -d 0 -e 0 -y install \
		vim git wget \
		zlib-devel openssl-devel

	bb-log-debug " - Installing Puppet repository..."
	rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
	bb-log-debug " - Installing Puppet..."
	yum -d 0 -e 0 -y install puppet

	bb-log-debug " - Installing dev tools..."
	installPython

	bb-log-debug " - Done!"
}

installPython() {
	# Python 3.3.5:
	if ! bb-exe? python3.3; then
		bb-log-debug " -- Installing Python 3.3.5..."
		wget http://python.org/ftp/python/3.3.5/Python-3.3.5.tar.xz
		tar xf Python-3.3.5.tar.xz
		pushd Python-3.3.5
		./configure --prefix=/usr/local --with-zlib=/usr/include --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
		make && make altinstall
		popd && rm -rf ./Python*
	fi
	bb-exit-on-error 1 "Failed to install Python 3.3.5!"

	# Setuptools and pip
	if ! bb-exe? easy_install-3.3; then
		bb-log-debug " -- Installing Setuptools..."
		# First get the setup script for Setuptools:
		wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py

		# Then install it for Python 2.7 and/or Python 3.3:
		python2.7 ez_setup.py
		bb-exit-on-error 1 "Failed to install easy_install-2.7!"
		python3.3 ez_setup.py
		bb-exit-on-error 1 "Failed to install easy_install-3.3!"
	fi

 	if ! bb-exe? pip3.3; then
 		bb-log-debug " -- Installing pip..."
		# Now install pip using the newly installed setuptools:
		easy_install-2.7 pip
		bb-exit-on-error 1 "Failed to install pip2.7!"
		easy_install-3.3 pip
		bb-exit-on-error 1 "Failed to install pip3.3!"
	fi
}

puppetModules() {
	for module in ${puppetModules_toInstall[@]}; do
		bb-log-debug " - Installing $module"
		puppet module install "$module"
	done
	bb-log-debug " - Done!"
}

executeScripts() {
	local dir="$1"
	for puppetFile in $(ls $dir); do
		bb-log-debug " - Applying $puppetFile..."
		puppet apply "$dir/$puppetFile"
		bb-exit-on-error 1 "Puppet apply failed!"
	done
	bb-log-debug " - Done!"
}

if [[ -f "/usr/local/lib/bashbooster/bashbooster.sh" ]]; then
        source "/usr/local/lib/bashbooster/bashbooster.sh"
else
        installBashBooster
fi
main