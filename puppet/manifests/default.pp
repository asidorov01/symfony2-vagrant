Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }


exec { 'wget_for_elasticsearch':
    command => 'wget -O /vagrant/elasticsearch-0.90.3.deb https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.3.deb',
    creates => "/vagrant/elasticsearch-0.90.3.deb",
    # path => '/usr/bin/',
}

exec { 'install_elasticsearch':
    command => 'dpkg -i /vagrant/elasticsearch-0.90.3.deb',
    creates => "/etc/elasticsearch/elasticsearch.yml",
    # path => '/usr/bin/',
}

exec { 'apt-get-update':
    command => 'apt-get update',
    path    => '/usr/bin/',
    timeout => 60,
    tries   => 3,
}


#### set nodejs ppa
class prepare {
  class { 'apt': }
  apt::ppa { 'ppa:chris-lea/node.js': }
}
include prepare


class nodePackages {
    package {'nodejs':
        ensure => present,
        require => Class['prepare'],
    }

    package {['grunt-cli', 'bower']:
        ensure   => present,
        provider => 'npm',
        require  => Package['nodejs'],
    }
}

class php ($version = 'latest') {

    #Add PHP modules here
    package { [ "php5", "php5-cli", "php5-fpm", "php5-mysql", "php5-curl", "php5-gd", "php-apc", "php5-xdebug", "php5-intl", "php5-mcrypt", "php5-imagick"]:
        ensure => $version,
        before => File['/etc/php5/cli/php.ini'],
        require => Exec['apt-get-update'],
    }

    file {['/etc/php5/fpm/php.ini', '/etc/php5/cli/php.ini']:
        ensure => file,
        owner  => 'root',
        require => Package['php5-fpm', 'php5-cli'],
        content => template("config/php.ini"),
    }

    file {'/etc/php5/conf.d/xdebug.ini':
        ensure => present,
        require => Package['php5-xdebug'],
        content => template("config/xdebug.ini"),
    }

    file {'/etc/php5/fpm/pool.d/www.conf':
        ensure => present,
        require => Package['nginx', 'php5-fpm'],
        content => template("config/php5-fpm-www.conf"),
    }

    service {'php5-fpm':
        ensure => running,
        enable => true,
        require => Package['php5', 'php5-fpm'],
        subscribe => File['/etc/php5/fpm/php.ini', '/etc/php5/fpm/pool.d/www.conf'],
    }

    exec { 'install-composer':
        command => 'curl -sS https://getcomposer.org/installer | php && /bin/mv composer.phar /usr/local/bin/composer',
        path    => '/usr/bin',
        require => Package['php5-cli', 'curl'],
    }
}

#### install nginx
class nginx ($version = 'latest') {
    package {'nginx':
        ensure => $version,
        before => File['/etc/nginx/nginx.conf'],
        require => Exec['apt-get-update'],
    }

    package {'apache2':
        ensure => absent,
        before => Package['nginx']
    }


    file {'/etc/nginx/nginx.conf':
        ensure => file,
        owner  => 'www-data'
    }

    file {'/etc/nginx/sites-enabled/symfony2':
        ensure => present,
        require => Package['nginx', 'php5-fpm'],
        content => template("config/nginx-virtual-host.ini"),
    }

    service {'nginx':
        ensure => running,
        enable => true,
        subscribe => File['/etc/nginx/nginx.conf', '/etc/nginx/sites-enabled/symfony2'],

    }

    # service {'apache2':
    #     ensure  => stopped,
    #     require => Service['nginx'],
    # }

}

#### install nginx
class elasticsearch () {

    file {'/etc/elasticsearch/elasticsearch.yml':
        ensure => file,
        require => Exec['wget_for_elasticsearch', 'install_elasticsearch'],
    }

    service {'elasticsearch':
        ensure => running,
        enable => true,
    }

    #Package['update-sun-jre'] -> Exec['wget_for_elasticsearch']

}

#### install mysql
class mysql5 ($version = 'latest') {

    $mysqlPackages = ['mysql-server', 'mysql-common', 'mysql-client']

    package { $mysqlPackages:
        ensure => $version,
        before => File['/etc/mysql/my.cnf'],
        require => Exec['apt-get-update'],
    }

    file {'/etc/mysql/my.cnf':
        ensure => file,
        owner  => 'root',
        content => template("config/my.cnf")
    }

    service {'mysql':
        ensure => running,
        enable => true,
        subscribe => File['/etc/mysql/my.cnf'],
    }

}

class dev ($version = 'latest') {
    $devPackages = [ "curl", "git", "capistrano", "rubygems", "openjdk-7-jdk", "libaugeas-ruby", "mc", "htop", "imagemagick" ]

    package { $devPackages:
        ensure => installed,
        require => Exec['apt-get-update'] ,
    }

}

# service { 'php5-fpm':
#   ensure     => running,
#   enable     => true,
#   hasrestart => true,
#   hasstatus  => true,
#   require    => Package['php5-fpm'],
# }

include mysql5
include nginx
include php
include nodePackages
include dev


    # class apache ($version = 'latest') {
    #   package {'httpd':
    #     ensure => $version, # Get version from the class declaration
    #     before => File['/etc/httpd.conf'],
    #   }
    #   file {'/etc/httpd.conf':
    #     ensure  => file,
    #     owner   => 'httpd',
    #     content => template('apache/httpd.conf.erb'), # Template from a module
    #   }
    #   service {'httpd':
    #     ensure => running,
    #     enable => true,
    #     subscribe => File['/etc/httpd.conf'],
    #   }
    # }
