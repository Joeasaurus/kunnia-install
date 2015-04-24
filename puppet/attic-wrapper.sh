#!/usr/bin/env bash

AWS_BUCKET="cloud.kunniagaming.net"
AWS_COMMAND="/usr/local/bin/aws --region $(/usr/local/bin/aws s3api get-bucket-location --output text --bucket $AWS_BUCKET)"

COMMAND="$1"
[[ "$COMMAND" != "attic" ]] && echo "Wrong command" && exit 5
shift

/usr/local/bin/attic $@
if [[ $? -eq 0 ]]; then
	"$AWS_COMMAND" s3 sync "$HOME" "s3://$AWS_BUCKET/$USER"
	[[ $? -ne 0 ]] && echo "!! FAILED TO SYNC TO S3 !!" && exit 2
else
	echo "!! FAILED TO RUN ATTIC !!"
	exit 1
fi
