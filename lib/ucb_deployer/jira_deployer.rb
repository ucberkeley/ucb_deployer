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

      tasks = self.load_tasks()
      self.execute_config_tasks(tasks)
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


protected

    def load_tasks()
      # TODO: Automatically load tasks so we don't have to manually specify each one
      #
      #tasks_path = "#{File.expand_path(File.dirname(__FILE__))}/config_tasks/jira/"
      #Dir.entries(tasks_path).select { |file| file.match(/^[a-z]/) }
      #tasks.each do |task|
      #  klass_name = self.file_name_to_class_name(task)
      #  klass = ::Kernel.const_get("UcbDeployer::ConfigTasks::Jira::#{klass_name}")
      #  klass.new(self).execute()
      #end

      [ UcbDeployer::ConfigTasks::Jira::ConfigIstBanner.new(self),
        UcbDeployer::ConfigTasks::Jira::ConfigCasAuth.new(self),
        UcbDeployer::ConfigTasks::Jira::ConfigJiraConfigProperties.new(self),
        UcbDeployer::ConfigTasks::Jira::ConfigAppProperties.new(self),
        UcbDeployer::ConfigTasks::Jira::RemoveConflictingJarFiles.new(self), ]
    end

    def file_name_to_class_name(filename)
      filename.gsub(/\.rb/, "").split("_").map(&:capitalize).join()
    end

    def execute_config_tasks(tasks)
      tasks.each { |task| task.execute() }
    end
  end
end

