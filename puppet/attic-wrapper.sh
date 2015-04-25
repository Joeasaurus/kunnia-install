#!/usr/bin/env bash

LOCK_FILE="$HOME/.attic"
exit_clean() {
	echo "$1"
	rm -rf "$LOCK_FILE"
	exit $2
}
while [[ -f "$LOCK_FILE" ]]; do
	sleep 2
done
touch "$LOCK_FILE"

AWS_BUCKET="cloud.kunniagaming.net"
AWS_COMMAND="/usr/local/bin/aws --region $(/usr/local/bin/aws s3api get-bucket-location --output text --bucket $AWS_BUCKET)"

COMMAND="$1"
[[ "$COMMAND" != "attic" ]] && exit_clean "Wrong command" 5
shift

/usr/local/bin/attic $@
if [[ $? -eq 0 ]]; then
	$AWS_COMMAND s3 sync "$HOME" "s3://$AWS_BUCKET/$USER"
	[[ $? -ne 0 ]] && exit_clean "!! FAILED TO SYNC TO S3 !!" 2
else
	exit_clean "!! FAILED TO RUN ATTIC !!" 1
fi
exit_clean "Complete!" 0
