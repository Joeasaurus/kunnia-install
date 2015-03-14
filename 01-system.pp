### System ###

# Install Python 3.3
class { 'python' :
	version    => '3.3',
	pip        => true,
	dev        => true,
	virtualenv => true,
	gunicorn   => false,
}