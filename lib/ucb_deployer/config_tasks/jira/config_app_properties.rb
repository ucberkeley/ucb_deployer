module UcbDeployer::ConfigTasks
  module Jira
    class ConfigAppProperties

      def initialize(config)
        @config= config
      end

      def execute()
        file_data = File.readlines(self.jira_app_properties_path()).map do |line|
          if /(#{Regexp.quote(self.jira_home_token())})/.match(line)
            "#{self.jira_home_token()} #{@config.data_dir()}"
          else
            line
          end
        end

        File.open(self.jira_app_properties_path(), "w") do |io|
          file_data.each { |line| io.puts(line) }
        end
      end


      def jira_home_token()
        "jira.home ="
      end

      def jira_app_properties_path()
        "#{@config.build_dir()}/src/edit-webapp/WEB-INF/classes/jira-application.properties"
      end

    end
  end
end