
module UcbDeployer
  class JiraDeployer < Deployer
    
    def initialize(config_file = "#{ENV['HOME']}/.ucb_deployer/config/jira/deploy.yml")
      self.debug("Using config file: #{config_file}")
      self.load_config(config_file)
    end
    
    def export()
      self.info("Exporting from: #{self.svn_project_url()}/jira-#{self.version()}")
      
      Dir.chdir("#{self.build_dir()}") do
        FileUtils.rm_rf("#{self.build_dir()}/src")
        `svn export #{self.svn_project_url()}/jira-#{self.version()}`
        FileUtils.mv("jira-#{self.version()}", "src")
      end
    end
    
    def configure()
      self.info("Configuring application.")
      ConfigCasAuth.new(self).execute()
      ConfigAppProperties.new(self).execute()
      ConfigJiraConfigProperties.new(self).execute()
      ConfigIstBanner.new(self).execute()
      RemoveConflictingJarFiles.new(self).execute()
    end

    def build()
      self.info("Building application.")
      Dir.chdir("#{self.build_dir()}/src") { `sh #{self.build_dir()}/src/build.sh` }
    end

    def deploy()
      self.info("Deploying application.")
      
      if File.exists?("#{self.deploy_dir()}/#{self.war_name()}")
        FileUtils.rm_rf(Dir["#{self.deploy_dir()}/#{self.war_name()}"])
      end

      FileUtils.mkdir("#{self.deploy_dir()}/#{self.war_name()}")
      `mv #{self.build_dir()}/src/dist-tomcat/atlassian-jira-*.war #{self.deploy_dir()}/#{self.war_name()}/#{self.war_name()}.war`
      `cd #{self.deploy_dir()}/#{self.war_name()}/ && jar -xvf #{self.war_name()}.war`
      `rm #{self.deploy_dir()}/#{self.war_name()}/#{self.war_name()}.war`
    end

    def rollback()
    end

  end
end

