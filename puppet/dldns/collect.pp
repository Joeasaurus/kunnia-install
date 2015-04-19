class dldns::collect {
	if (!defined(File['/bin/r53u'])) {
		fail('Error: Binary not installed. Try including ::dldns::install?')
	}
	::Dldns::R53u <<| |>>
}