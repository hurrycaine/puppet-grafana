# == Class grafana::install
#
class grafana::install {
  case $::grafana::install_method {
    'docker': {
      docker::image { 'grafana/grafana':
        image_tag => 'latest',
        require   => Class['docker']
      }
    }
    'package': {
      case $::osfamily {
        'Debian': {
          package { 'libfontconfig1':
            ensure => present
          }

          wget::fetch { 'grafana':
            source      => $::grafana::package_source,
            destination => '/tmp/grafana.deb'
          }

          package { $::grafana::package_name:
            ensure   => present,
            provider => 'dpkg',
            source   => '/tmp/grafana.deb',
            require  => [Wget::Fetch['grafana'],Package['libfontconfig1']]
          }
        }
        'RedHat': {
          package { 'fontconfig':
            ensure => present
          }

          package { $::grafana::package_name:
            ensure   => present,
            provider => 'rpm',
            source   => $::grafana::package_source,
            require  => Package['fontconfig']
          }
        }
        default: {
          fail("${::operatingsystem} not supported")
        }
      }
    }
    'repo': {
      case $::osfamily {
        'Debian': {
          package { 'libfontconfig1':
            ensure => present
          }

          if ( $::grafana::manage_package_repo ){
            if !defined( Class['apt'] ) {
              class { 'apt': }
            }
            apt::source { 'grafana':
              location => 'https://packagecloud.io/grafana/stable/debian',
              release  => 'wheezy',
              repos    => 'main',
              key      =>  {
                'id'     => 'D59097AB',
                'source' => 'https://packagecloud.io/gpg.key'
              },
              before   => Package[$::grafana::package_name],
            }
          }

          package { $::grafana::package_name:
            ensure  => present,
            require => Package['libfontconfig1']
          }
        }
        'RedHat': {
          package { 'fontconfig':
            ensure => present
          }

          if ( $::grafana::manage_package_repo ){
            yumrepo { 'grafana':
              descr    => 'grafana repo',
              baseurl  => 'https://packagecloud.io/grafana/stable/el/6/$basearch',
              gpgcheck => 1,
              gpgkey   => 'https://packagecloud.io/gpg.key https://grafanarel.s3.amazonaws.com/RPM-GPG-KEY-grafana',
              enabled  => 1,
              before   => Package[$::grafana::package_name],
            }
          }

          package { $::grafana::package_name:
            ensure  => present,
            require => Package['fontconfig']
          }
        }
        default: {
          fail("${::operatingsystem} not supported")
        }
      }
    }
    'archive': {
      # create log directory /var/log/grafana (or parameterize)

      archive { 'grafana':
        ensure           => present,
        checksum         => false,
        root_dir         => 'public',
        strip_components => 1,
        target           => $::grafana::install_dir,
        url              => $::grafana::archive_source
      }

      user { 'grafana':
        ensure  => present,
        home    => $::grafana::install_dir,
        require => Archive['grafana']
      }

      file { $::grafana::install_dir:
        ensure       => directory,
        group        => 'grafana',
        owner        => 'grafana',
        recurse      => true,
        recurselimit => 3,
        require      => User['grafana']
      }
    }
    default: {
      fail("Installation method ${::grafana::install_method} not supported")
    }
  }
}
