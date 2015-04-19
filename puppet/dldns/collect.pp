class dldns::collect (
	masterless = false
) {
	if (!defined(File['/bin/r53u'])) {
		fail('Error: Binary not installed. Try including ::dldns::install?')
	}
	::Dldns::R53u <<| |>>
}