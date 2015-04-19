define dldns::record (
	$masterless = false,
	$provider   = 'r53',
	$record
) {
	validate_string($provider)
	validate_hash($record)
	validate_string($record[recordname])
	$recordname_sha = sha1($record[recordname])
	new_record = {
		title 	   => $title,
		zone       => $record[zone],
	    ttl        => $record[ttl],
	    localname  => $record[localname],
	    recordname => $record[recordname]
	}
	if ($provider == 'r53') {
		$rtitle = "R53 Record - ${recordname_sha}"
		if (masterless) {
			::dldns::r53u {$rtitle:
				record      => $new_record,
				call_binary => true
			}
		} else {
			@@::dldns::r53u {$rtitle:
				record => $new_record
			}
		}
	} else {
		fail('Error: Only "r53" is supported for ::dl::dns::record at this time!')
	}
}