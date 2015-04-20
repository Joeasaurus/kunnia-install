class dldns::collect {
	if (! defined(Class['::dldns::install'])) {
		fail('Error: You must declare ::dldns::install before collecting records!')
	}
	::Dldns::R53u <<| |>>
}