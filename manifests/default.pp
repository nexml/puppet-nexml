# This manifest installs the nexml website

$docroot   = '/var/www/html/'
$nexmlweb  = 'https://github.com/nexml/nexml.github.io.git'
$nexmlroot = '/var/www/html/nexml'
$webfolder = '/var/www/html/nexml.github.io'
$apacheusr = 'www-data'

# update the $PATH environment variable
Exec {
  path => [
		"/usr/local/sbin",
		"/usr/local/bin",
		"/usr/sbin",
		"/usr/bin",
		"/sbin",
		"/bin",
	] 
}

# disable timeout for all provisioning operations
Exec { timeout => 0 }

# This class contains the instructions for configuring and installing all dependencies,
class install {

	# keep package information up to date
	exec {
		"apt_update":
		command => "/usr/bin/apt-get update"
	}

	# install packages.
	package {
		"wget":                ensure => installed, require => Exec["apt_update"];
		"tar":                 ensure => installed, require => Exec["apt_update"];
		"git":                 ensure => installed, require => Exec["apt_update"];
		"curl":                ensure => installed, require => Exec["apt_update"];
		"gzip":                ensure => installed, require => Exec["apt_update"];
		"perl":                ensure => installed, require => Exec["apt_update"];
		"build-essential":     ensure => installed, require => Exec["apt_update"];
		"apache2":             ensure => installed, require => Exec["apt_update"];
		"libxml-parser-perl":  ensure => installed, require => Exec["apt_update"];
		"libhtml-parser-perl": ensure => installed, require => Exec["apt_update"];
		"libxml2":             ensure => installed, require => Exec["apt_update"];
		"libxml2-dev":         ensure => installed, require => Exec["apt_update"];
		"libxml-libxml-perl":  ensure => installed, require => Exec["apt_update"];
		"libwww-perl":         ensure => installed, require => Exec["apt_update"];
		"libxml-twig-perl":    ensure => installed, require => Exec["apt_update"];
		"libtemplate-perl":    ensure => installed, require => Exec["apt_update"];
	}
	
	# ensure apache2 service is running
	service { 
		'apache2': 
			enable  => true,
			ensure  => running,
			require => [ Package['apache2'], Exec['apache2.conf'] ];
	}
	
	exec {	     
	
		# install cpanm
		"cpanm":
			command => "curl -L http://cpanmin.us | perl - --sudo App::cpanminus",
			require => Package[ 'curl', 'perl', 'build-essential', 'git' ];
			
		# clone nexmlweb
		"nexmlweb":
			command => "git clone $nexmlweb",
			cwd     => $docroot,
			creates => $webfolder,
			require => [ Package['apache2'], Package['git'] ];
			
		# install CPAN packages
		"xml-xml2json":
			command => 'cpanm --notest XML::XML2JSON',
			require => [ Exec['cpanm'], Package[ 'libxml-libxml-perl' ] ];
		"bio-phylo":
			command => 'cpanm --notest git://github.com/rvosa/bio-phylo.git',
			require => Exec['cpanm'];
		"bioperl":
			command => 'cpanm --notest git://github.com/bioperl/bioperl-live.git',
			require => Exec['cpanm'];
		
		# install sitebuilder packages
		"sitebuilder":
			command => 'cpanm .',
			cwd     => '/var/www/html/nexml.github.io/sitebuilder/src',
			require => [ Exec['cpanm'] ];
		
		# copy files to docroot
		"copy":
			command => "cp --recursive $webfolder/* $docroot",
			require => Exec['nexmlweb'];
		
		# apply edited apache2.conf
		"apache2.conf":
			command => "cat $webfolder/conf/apache2.conf > /etc/apache2/apache2.conf",
			require => [ Package['apache2'], Exec['nexmlweb'] ];
	}
}

# make sure all the cleanup happens last
class { 'install':
      stage => main,
}
