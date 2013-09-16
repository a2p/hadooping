class hadoop_a2p  {
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

    include  jdk_oracle_1_6

    file {"cloudera-cdh4.repo":
      name   => "/etc/yum.repos.d/cloudera-cdh4.repo",
      owner  => "root",
      group  => "root",
      source => "puppet:///modules/hadoop_a2p/etc/yum.repos.d/cloudera-cdh4.repo",
      before => Package["hadoop-0.20-conf-pseudo"]
    }

    package { "hadoop-0.20-conf-pseudo" :
    ensure => present,
    require => file["cloudera-cdh4.repo"]
    }
    package { "hue-plugins" :
    ensure => present,
    require => package["hadoop-0.20-conf-pseudo"]
    }

    file {"core-site.xml":
      name => "/etc/hadoop/conf/core-site.xml",
      owner => "root",
      group => "root",
      source => "puppet:///modules/hadoop_a2p/etc/hadoop/conf/core-site.xml",
      before => service["hadoop-hdfs-namenode"],
      require => package["hadoop-0.20-conf-pseudo"]
    }

    file {"hdfs-site.xml":
      name => "/etc/hadoop/conf/hdfs-site.xml",
      owner => "root",
      group => "root",
      source => "puppet:///modules/hadoop_a2p/etc/hadoop/conf/hdfs-site.xml",
      before => service["hadoop-hdfs-namenode"],
      require => package["hadoop-0.20-conf-pseudo"]      
    }

    service { "hadoop-hdfs-namenode" :
      ensure => "running",
      enable => "true",
      require => exec["format dfs file system"]	 	      
    }
    service { "hadoop-hdfs-secondarynamenode" :
      ensure => "running",
      enable => "true",
      require => service["hadoop-hdfs-namenode"]	 	      
    }
    service { "hadoop-hdfs-datanode" :
      ensure => "running",
      enable => "true",
      require => service["hadoop-hdfs-secondarynamenode"]	 	      
    }

    exec { "format dfs file system" :
      command => 'hdfs namenode -format',
      user => hdfs,
      unless  => [ "hadoop fs -ls /" ],
      require => package["hadoop-0.20-conf-pseudo"],
      timeout => 20	 
    }

    exec { "make tmp directory" :
      command => 'hadoop fs -mkdir /tmp && hadoop fs -chmod -R 1777 /tmp',
      user => hdfs,
      unless  => [ 'hadoop fs -ls /tmp' ],
      require => service["hadoop-hdfs-datanode"]	 	
    }
    
    exec { "create mapreduce system directories" :
      command => 'hadoop fs -mkdir -p /var/lib/hadoop-hdfs/cache/mapred/mapred/staging && \ 
      hadoop fs -chmod 1777 /var/lib/hadoop-hdfs/cache/mapred/mapred/staging && \
      hadoop fs -chown -R mapred /var/lib/hadoop-hdfs/cache/mapred',
      user => hdfs,
      unless  => [ 'hadoop fs -ls /var/lib/hadoop-hdfs/cache/mapred/mapred/staging' ],
      require => service["hadoop-hdfs-datanode"]	 	
    }

    service { "hadoop-0.20-mapreduce-tasktracker" :
      ensure => "running",
      enable => "true",
      require => exec["create mapreduce system directories"]	 	      
    }
    service { "hadoop-0.20-mapreduce-jobtracker" :
      ensure => "running",
      enable => "true",
      require => exec["create mapreduce system directories"]	 	      
    }
}

