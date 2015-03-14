#!/usr/bin/env bash

main() {
	printMessage "Running Puppet Manifests..."
	executeScripts .
	printMessage "Complete."
}

printMessage() {
	echo "[KunInst] $1"
}

executeScripts() {
	local dir="$1"
	for puppetFile in $(ls $dir); do
		printMessage "Applying $puppetFile..."
		puppet apply "$puppetFile"
		if [[ $? -ne 0 ]]; then
			printMessage "There was an error, exiting!"
			exit 1
		fi
	done
}

main