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
	"stankevich-python"
	"shr3kst3r-glacier"
	"pdxcat-autofs"
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
	bb-log-debug " - Preparing Yum..."
	yum groups mark convert

	bb-log-debug " - Installing base packages..."
	yumInstall g "Development tools"
	yumInstall vim git wget \
			   zlib-devel openssl-devel \
			   libacl-devel

	bb-log-debug " - Installing system-level dependencies..."
	installS3Fuse

	bb-log-debug " - Installing Puppet repository..."
	rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
	bb-log-debug " - Installing Puppet..."
	yumInstall puppet

	bb-log-debug " - Installing dev tools..."
	installPython
	installAwsCli

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

installAwsCli() {
	if ! bb-exe? aws; then
		bb-log-debug " -- Installing AWS CLI tools..."
		pip3.3 install awscli
		bb-exit-on-error 1 "Failed to install awscli!"
	fi
}

installS3Fuse() {
	modprobe fuse
	if [[ $? -eq 1 ]]; then
		bb-log-debug " -- Installing FUSE kernel module..."
		yumInstall kernel-devel libxml2-devel pkgconfig \
				   fuse fuse-devel openssl-devel libcurl-devel \
				   gnutls gnutls-devel nss
	fi
	modprobe fuse
	bb-exit-on-error 1 "Failed to install FUSE!"

	if ! bb-exe? s3fs; then
		bb-log-debug " -- Installing s3fs-fuse..."
		git clone https://github.com/s3fs-fuse/s3fs-fuse.git && \
		pushd s3fs-fuse && \
		./autogen.sh && ./configure && \
		make && make install && \
		popd
		bb-exit-on-error 1 "Failed to install s3fs-fuse!"
	fi

	bb-log-debug " -- Configuring s3fs-fuse..."
	local passwdContents="cloud.kunniagaming.net:$AWSACCESSKEYID:$AWSSECRETACCESSKEY"
	echo  "$passwdContents" > /etc/passwd-s3fs
	chmod 640 /etc/passwd-s3fs
	bb-assert "[[ $(cat /etc/passwd-s3fs) == $passwdContents ]]"
	bb-assert '[[ $(stat -c "%a" /etc/passwd-s3fs) == 640 ]]'
	bb-log-debug " -- Testing mount capability..."
	bb-assert 's3fs cloud.kunniagaming.net /mnt'
	umount /mnt
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

if [[ ! -f "/usr/local/lib/bashbooster/bashbooster.sh" ]]; then
	installBashBooster
fi
source "/usr/local/lib/bashbooster/bashbooster.sh"
main