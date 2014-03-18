define openam::instance (
  $version,
  $admin_pw,
  $agent_pw,
  $config_store_admin_password,
  $instance                = $name,
  $server_url              = "http://${::fqdn}:8080",
  $webapp                  = 'openam',
  $data_store              = 'embedded',
  $cookie_domain           = ".${::fqdn}",
  $config_store_ssl        = 'SIMPLE',
  $config_store_host       = 'localhost',
  $config_store_port       = 1389,
  $config_store_admin_port = 5444,
  $config_store_jmx_port   = 1689,
  $config_store_base_dn    = 'dc=openam',
  $config_store_admin_user = 'cn=Directory Manager',) {
  include tomcat

  $instance_home = "${::tomcat::home}/${instance}"

  if (!defined(Tomcat::Instance[$instance])) {
    tomcat::instance { $instance: }
  }

  tomcat::webapp::maven { "${instance}:${webapp}":
    webapp     => $webapp,
    instance   => $instance,
    artifactid => 'openam-server',
    groupid    => 'org.forgerock.openam',
    version    => $version,
    repos      => 'http://maven.forgerock.org/repo/releases',
  }

  if (!defined(Maven["/usr/share/java/openam-distribution-ssoadmintools-${version}.zip"])) {
    maven { "/usr/share/java/openam-distribution-ssoadmintools-${version}.zip":
      id    => "org.forgerock.openam:openam-distribution-ssoadmintools:${version}:zip",
      repos => 'http://maven.forgerock.org/repo/releases',
    }
  }

  if (!defined(Maven["/usr/share/java/openam-distribution-ssoconfiguratortools-${version}.zip"])) {
    maven { "/usr/share/java/openam-distribution-ssoconfiguratortools-${version}.zip":
      id    => "org.forgerock.openam:openam-distribution-ssoconfiguratortools:${version}:zip",
      repos => 'http://maven.forgerock.org/repo/releases',
    }
  }

  exec { "${instance}:unzip:ssoadmintools":
    command => "/usr/bin/sudo -u ${instance} /usr/bin/unzip /usr/share/java/openam-distribution-ssoadmintools-${version}.zip -d ${instance_home}/admintools",
    creates => "${instance_home}/admintools",
    require => File[$instance_home],
  }

  exec { "${instance}:unzip:ssoconfiguratortools":
    command => "/usr/bin/sudo -u ${instance} /usr/bin/unzip /usr/share/java/openam-distribution-ssoconfiguratortools-${version}.zip -d ${instance_home}/configuratortools",
    creates => "${instance_home}/configuratortools",
    require => File[$instance_home],
  }

  Ini_setting {
    path    => "${instance_home}/.install.conf",
    section => '',
    require => File[$instance_home],
  }

  ini_setting { "${instance}:SERVER_URL":
    setting => 'SERVER_URL',
    value   => $server_url,
  } ->
  ini_setting { "${instance}:DEPLOYMENT_URI":
    setting => 'DEPLOYMENT_URI',
    value   => "/${webapp}",
  } ->
  ini_setting { "${instance}:BASE_DIR":
    setting => 'BASE_DIR',
    value   => "${instance_home}/openam",
  } ->
  ini_setting { "${instance}:locale":
    setting => 'locale',
    value   => 'en_US',
  } ->
  ini_setting { "${instance}:PLATFORM_LOCALE":
    setting => 'PLATFORM_LOCALE',
    value   => 'en_US',
  } ->
  ini_setting { "${instance}:AM_ENC_KEY":
    setting => 'AM_ENC_KEY',
    value   => '',
  } ->
  ini_setting { "${instance}:ADMIN_PWD":
    setting => 'ADMIN_PWD',
    value   => $admin_pw,
  } ->
  ini_setting { "${instance}:AMLDAPUSERPASSWD":
    setting => 'AMLDAPUSERPASSWD',
    value   => $agent_pw,
  } ->
  ini_setting { "${instance}:COOKIE_DOMAIN":
    setting => 'COOKIE_DOMAIN',
    value   => $cookie_domain,
  } ->
  ini_setting { "${instance}:DATA_STORE":
    setting => 'DATA_STORE',
    value   => $data_store,
  } ->
  ini_setting { "${instance}:DIRECTORY_SSL":
    setting => 'DIRECTORY_SSL',
    value   => $config_store_ssl,
  } ->
  ini_setting { "${instance}:DIRECTORY_SERVER":
    setting => 'DIRECTORY_SERVER',
    value   => $config_store_host,
  } ->
  ini_setting { "${instance}:DIRECTORY_PORT":
    setting => 'DIRECTORY_PORT',
    value   => $config_store_port,
  } ->
  ini_setting { "${instance}:DIRECTORY_ADMIN_PORT":
    setting => 'DIRECTORY_ADMIN_PORT',
    value   => $config_store_admin_port,
  } ->
  ini_setting { "${instance}:DIRECTORY_JMX_PORT":
    setting => 'DIRECTORY_JMX_PORT',
    value   => $config_store_jmx_port,
  } ->
  ini_setting { "${instance}:ROOT_SUFFIX":
    setting => 'ROOT_SUFFIX',
    value   => $config_store_base_dn,
  } ->
  ini_setting { "${instance}:DS_DIRMGRDN":
    setting => 'DS_DIRMGRDN',
    value   => $config_store_admin_user,
  } ->
  ini_setting { "${instance}:DS_DIRMGRPASSWD":
    setting => 'DS_DIRMGRPASSWD',
    value   => $config_store_admin_password,
  } ->
  exec { "${instance}:config":
    command => "/usr/bin/sudo -u ${instance} java \$JAVA_OPTS -jar ${instance_home}/configuratortools/openam-configurator-tool-${version}.jar -f ${instance_home}/.install.conf",
    creates => "${instance_home}/openam",
    cwd     => $instance_home,
    require => Exec["${instance}:unzip:ssoconfiguratortools"],
  }
}