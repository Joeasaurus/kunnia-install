#!/usr/bin/env bash

## PREPREP
unset CDPATH
cd "$( dirname "${BASH_SOURCE[0]}" )"
random() {
	dd if=/dev/urandom bs=8 count=1 2>/dev/null | base64
}

## GLOBAL SETTINGS
export BB_LOG_USE_COLOR=true
export BB_WORKSPACE="/tmp/kunnia-install-$(random)"
BB_LOG_LEVEL="$1"
[[ -z "$1" ]] && BB_LOG_LEVEL=INFO
export BB_LOG_LEVEL

puppetModules_toInstall=(
	"stahnma-epel"
	"spiette-selinux"
	"stankevich-python"
	"shr3kst3r-glacier"
	"example42-autofs"
	"garethr-docker"
	"local-dldns"
)

main() {
	bb-log-info "Configuring base system..."
	baseSystem
	bb-log-info "Installing Puppet modules..."
	puppetModules puppet
	bb-log-info "Running Puppet manifests..."
	executeScripts puppet
	bb-exit 0 "Complete!"
}

yumInstall() {
	local installType='install'
	if [[ "$1" == "g" ]]; then
		installType='groupinstall'
		shift
	fi
	local package="$@"
	yum -d 0 -e 0 -y $installType $package
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
	bb-log-debug " - Preparing System..."
	mountDisk /dev/xvdb /opt
	yum groups mark convert
	yum -d 0 -e 0 -y update

	bb-log-debug " - Installing base packages..."
	yumInstall g "Development tools"
	yumInstall vim git wget unzip \
			   zlib-devel openssl-devel \
			   libacl-devel

	bb-log-debug " - Installing system-level dependencies..."
	yumInstall autofs

	bb-log-debug " - Installing Puppet repository..."
	rpm -i --quiet http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
	bb-log-debug " - Installing Puppet..."
	yumInstall puppet

	bb-log-debug " - Installing dev tools..."
	installPython
	installAwsCli
	installOtherTools

	bb-log-debug " - Done!"
}

mountDisk() {
	# This is crude, ideally the OS would use the whole first disk so we could expand it.
	if [[ "$(fdisk -l | grep $1)" ]]; then
		mkfs.ext4 "$1" && mount -t ext4 "$1" "$2"
	else
		echo "mountDisk: $1 not present, skipping mount."
	fi
}

installOtherTools() {
	bb-log-debug " -- Installing other dev tools..."
	if ! bb-exe? cli53; then
		pip2.7 install cli53
		bb-exit-on-error 1 "Failed to install cli53!"
	fi
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

installAwsCli() {
	if ! bb-exe? aws; then
		bb-log-debug " -- Installing AWS CLI tools..."
		pip3.3 install awscli
		bb-exit-on-error 1 "Failed to install awscli!"
	fi
}

# adduser user
# git clone https://github.com/clevcode/docker-cmd.git
# cd docker-cmd/
# make clean all
# sed this !! docker run --name="${JAILNAME}_${usr}" -h "$JAIL_HOSTNAME" -v "$REAPER:/sbin/reaper:ro" -v "$dir:$dir:rw" -d "$JAILNAME" /sbin/reaper
# make install
# docker-mkjail user
# docker-cmd jail_user <INSTALL COMMANDS>

puppetModules() {
	for module in ${puppetModules_toInstall[@]}; do
		bb-log-debug " - Installing $module"
		if [[ "$module" =~ local-(.*) ]]; then
			rm -rf "/etc/puppet/modules/${BASH_REMATCH[1]}"
			cp -rf "$1/${BASH_REMATCH[1]}" /etc/puppet/modules/
		else
			puppet module install "$module"
		fi
		bb-exit-on-error 1 "Error installing Puppet module [$module]"
	done
	bb-log-debug " - Done!"
}

setFact() {
	local factName="$1"
	local factData="$2"
	mkdir -p /etc/facter/facts.d
	echo "$1=$2" > "/etc/facter/facts.d/$1.txt"
	facter | grep "$1"
}

executeScripts() {
	local dir="$1"
	setFact rundir "$(pwd)/$dir"
	for puppetFile in $(ls $dir/*.pp); do
		bb-log-debug " - Applying $puppetFile..."
		puppet apply "$puppetFile"
		bb-exit-on-error 1 "Puppet apply failed!"
	done
	bb-log-debug " - Done!"
}

if [[ ! -f "/usr/local/lib/bashbooster/bashbooster.sh" ]]; then
	installBashBooster
fi
source "/usr/local/lib/bashbooster/bashbooster.sh"
main