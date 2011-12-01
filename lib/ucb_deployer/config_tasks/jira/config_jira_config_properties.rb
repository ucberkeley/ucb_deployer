module UcbDeployer::ConfigTasks
  class ConfigJiraConfigProperties

    def initialize(config)
      @config = config
    end

    def execute()
      File.open(self.jira_config_properties_path(), "w") do |fd|
        fd.puts(self.projectkey_config())
      end
    end


    def projectkey_config()
      "jira.projectkey.pattern = ([A-Z][A-Z0-9]+)"
    end

    def jira_config_properties_path()
      "#{@config.data_dir()}/jira-config.properties"
    end
  end
end