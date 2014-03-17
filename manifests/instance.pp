define openam::instance (
  $version,
  $instance   	           	= $name,
  $admin_pw   	           	= sha1("${::uniqueid}admin${name}"),
  $agent_pw   	           	= sha1("${::uniqueid}agent${name}"),
  $config_store_host 	   	= 'localhost',
  $config_store_port   	   	= 1389,
  $config_store_admin_port 	= 5444,
  $config_store_jmx_port   	= 1689,
  $config_store_base_dn    	= 'dc=openam',
  $config_store_admin_user 	= 'cn=Directory Manager',
  $config_store_admin_password  = sha1("${::uniqueid}config${name}"),
) {
  include tomcat
  
  $instance_home = "${::tomcat::home}/${instance}"
  
  if (!defined(Tomcat::Instance[$instance])) {
    tomcat::instance { $instance: }
  }

  tomcat::webapp::maven { 'openam':
    instance   => $instance,
    artifactid => 'openam-server',
    groupid    => 'org.forgerock.openam',
    version    => $version,
    repos      => 'http://maven.forgerock.org/repo/releases',
  }

  if(!defined(Maven["/usr/share/java/openam-distribution-ssoadmintools-${version}.zip"])) {
    maven { "/usr/share/java/openam-distribution-ssoadmintools-${version}.zip":
      id    => "org.forgerock.openam:openam-distribution-ssoadmintools:${version}:zip",
      repos => 'http://maven.forgerock.org/repo/releases',
    }
  }

  if(!defined(Maven["/usr/share/java/openam-distribution-ssoconfiguratortools-${version}.zip"])) {
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

  ini_setting { "${instance}:ADMIN_PWD":
    setting => 'ADMIN_PWD',
    value   => $admin_pw,
  }
  
  ini_setting { "${instance}:AMLDAPUSERPASSWD":
    setting => 'AMLDAPUSERPASSWD',
    value   => $agent_pw,
  }

  ini_setting { "${instance}:DIRECTORY_SSL":
    setting => 'DIRECTORY_SSL',
    value   => 'SIMPLE',
  }

  ini_setting { "${instance}:DIRECTORY_SERVER":
    setting => 'DIRECTORY_SERVER',
    value   => $config_store_host,
  }

  ini_setting { "${instance}:DIRECTORY_PORT":
     setting => 'DIRECTORY_PORT',
    value   => $config_store_port,
  }
  
  ini_setting { "${instance}:DIRECTORY_ADMIN_PORT":
    setting => 'DIRECTORY_ADMIN_PORT',
    value   => $config_store_admin_port,
  }
  
  ini_setting { "${instance}:DIRECTORY_JMX_PORT":
    setting => 'DIRECTORY_JMX_PORT',
    value   => $config_store_jmx_port,
  }
  
  ini_setting { "${instance}:ROOT_SUFFIX":
    setting => 'ROOT_SUFFIX',
    value   => $config_store_base_dn,
  }
  
  ini_setting { "${instance}:DS_DIRMGRDN":
    setting => 'DS_DIRMGRDN',
    value   => $config_store_admin_user,
  }
  
  ini_setting { "${instance}:DS_DIRMGRPASSWD":
    setting => 'DS_DIRMGRPASSWD',
    value   => $config_store_admin_password,
  }
}
