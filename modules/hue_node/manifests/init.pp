class hue_node  {
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
    include  jdk_oracle_1_6

    file {"cloudera-cdh4.repo":
      name   => "/etc/yum.repos.d/cloudera-cdh4.repo",
      owner  => "root",
      group  => "root",
      source => "puppet:///modules/hue_node/etc/yum.repos.d/cloudera-cdh4.repo",
      before => Package["zookeeper"]
    }

    package { "zookeeper" :
      ensure  => present,
      require => file ["cloudera-cdh4.repo"]
    }
    package { "zookeeper-server" :
      ensure  => present,
      require => package ["zookeeper"]
    }
    package { "oozie" :
      ensure  => present,
      require => package ["zookeeper-server"]
    }
    package { "hue" :
      ensure  => present,
      require => package ["oozie"]
    }
    package { "hue-server" :
      ensure  => present,
      require => package ["hue"]
    }
    
    file {"hue.ini":
      name   => "/etc/hue/hue.ini",
      owner  => "root",
      group  => "root",
      source => "puppet:///modules/hue_node/etc/hue/hue.ini",
      before => service ["hue"],
      require => package ["hue-server"]      
    }

    service { "zookeeper-server":
      ensure  => running,
      enable  => true,
      require => [ Package["zookeeper-server"], 
      Exec["zookeeper-server-initialize"] ],
    } 

   exec { "zookeeper-server-initialize":
     command => "/usr/bin/zookeeper-server-initialize",
     user    => "zookeeper",
     creates => "/var/lib/zookeeper/version-2",
     require => Package["zookeeper-server"],
    }

    service { "oozie" :
      ensure  => "running",
      enable  => true,
      require => package ["oozie"]
    }

    file {"oozie-site.xml":
      name   => "/etc/oozie/conf/oozie-cite.xml",
      owner  => "root",
      group  => "root",
      source => "puppet:///modules/hue_node/etc/oozie/conf/oozie-site.xml",
      before => service ["oozie"],
      require => Package["oozie"]      
    }
    
     service { "hue" :
       ensure     => "running",
       subscribe  => file ["/etc/hue/hue.ini"],
       hasrestart => true,
       hasstatus  => true,
       enable     => "true",
       require    => package["hue"]     
     }
}

