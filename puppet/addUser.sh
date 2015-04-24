#!/bin/bash

AWS_BUCKET="cloud.kunniagaming.net"
AWS_COMMAND="aws --region $(/usr/local/bin/aws s3api get-bucket-location --output text --bucket $AWS_BUCKET)"

USER_ROOT=/opt

USER_NAME="$1"
USER_HOME="$USER_ROOT/$USER_NAME"
[[ -z "$USER_NAME" ]] && echo "-- Missing username as \$1" && exit 1
[[ -n "$(grep $USER_NAME /etc/passwd)" ]] && \
	echo "-- $USER_NAME already exists!" && exit 1

useradd -b "$USER_ROOT" -m "$USER_NAME"
if [[ $? -ne 0 ]]; then
	echo "-- Failed to create user!"
	exit 1
else
	echo "++ $USER_NAME successfully created!"
fi

if [[ -n "$($AWS_COMMAND s3 ls s3://$AWS_BUCKET/$USER_NAME)" ]]; then
	echo "++ Found existing home directory for $USER_NAME, syncing it down!"
	rm -rf "$USER_HOME/*" && rm -rf "$USER_HOME/.*"
	[[ $? -ne 0 ]] && echo "-- Could not clear $USER_HOME before sync!" && exit 1
	"$AWS_COMMAND" s3 sync "s3://$AWS_BUCKET/$USER_NAME" "$USER_HOME"
	[[ $? -ne 0 ]] && echo "-- Could not sync $USER_HOME down!" && exit 1
else
	echo "++ No directory found for $USER_NAME, I will create one.."
	mkdir -p "$USER_HOME/.ssh"
	echo 'command="/usr/local/bin/attic-wrapper $SSH_ORIGINAL_COMMAND"' \
		 > "$USER_HOME/.ssh/authorized_keys"
	[[ ! -f "$USER_HOME/.ssh/authorized_keys" ]] && \
		echo "-- Failed to create authorized_keys!" && exit 1
	echo "++ REMEMBER: You need to put their public ssh key in authorized_keys!!"
fi

chown -R "$USER_NAME.$USER_NAME" "$USER_HOME"
chmod -R 700 "$USER_HOME"

echo "!! COMPLETE :) !!"