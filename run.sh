#!/usr/bin/env bash

BB_LOG_USE_COLOR=true

puppetModules_toInstall=(
	"stahnma-epel"
	"yguenane-repoforge"
)

main() {
	echo "[KUNNIA] Installing BashBooster..."
	installBashBooster
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
	source /usr/local/lib/bashbooster/bashbooster.sh
}

baseSystem() {
	bb-log-debug " - Installing base packages..."
	yum groups mark convert
	yum -d 0 -e 0 -y groupinstall "Development tools"
	yum -d 0 -e 0 -y install vim git wget

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
		bb-log-debug " - Installing $module"
		puppet module install "$module"
	done
	bb-log-debug " - Done!"
}

executeScripts() {
	local dir="$1"
	for puppetFile in $(ls $dir); do
		bb-log-debug " - Applying $puppetFile..."
		puppet apply "$puppetFile"
		bb-exit-on-error 1 "Puppet apply failed!"
	done
	bb-log-debug " - Done!"
}

main