define dldns::record (
	$provider = 'r53',
	$record
) {
	validate_string($provider)
	validate_hash($record)
	validate_string($record[recordname])
	$recordname_sha = sha1($record[recordname])
	record[title] = $title
	if ($provider == 'r53') {
		@@dldns::r53u {"R53 Record - ${recordname_sha}":
			record => $record
		}
	} else {
		fail('Error: Only "r53" is supported for ::dl::dns::record at this time!')
	}
}