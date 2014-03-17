define openam::instance (
  $version,
  $instance = $name,
  
) {
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
}
