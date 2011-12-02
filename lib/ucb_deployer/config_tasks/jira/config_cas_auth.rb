module UcbDeployer::ConfigTasks
  module Jira
    class ConfigCasAuth

      def initialize(config)
        @config = config
      end

      def execute()
        self.update_seraph_config_xml()
        self.update_web_xml()
      end


      def seraph_config_path()
        "#{@config.build_dir()}/src/webapp/WEB-INF/classes/seraph-config.xml"
      end

      def seraph_config_auth_token()
        "com.atlassian.jira.security.login.JiraSeraphAuthenticator"
      end

      def seraph_config_logout_url_token()
        "/secure/Logout!default.jspa"
      end

      def cas_authenticator_class()
        "org.soulwing.cas.apps.atlassian.JiraCasAuthenticator"
      end

      def cas_logout_url()
        "/casLogout.action"
      end

      def web_xml_path()
        "#{@config.build_dir()}/src/webapp/WEB-INF/web.xml"
      end

      def web_xml_token()
        "<!--This filter is used to determine is there are any Application Errors before any pages are accessed"
      end

      def update_seraph_config_xml()
        seraph_xml_data = File.readlines(self.seraph_config_path()).map do |line|
          if m = /(#{Regexp.quote(self.seraph_config_auth_token())})/.match(line)
            "#{m.pre_match}#{self.cas_authenticator_class()}#{m.post_match}"
          elsif m = /(#{Regexp.quote(self.seraph_config_logout_url_token())})/.match(line)
            "#{m.pre_match}#{@config.cas_server_url()}/logout#{m.post_match}"
          else
            line
          end
        end

        File.open(self.seraph_config_path(), "w") do |io|
          seraph_xml_data.each { |line| io.puts(line) }
        end
      end

      def update_web_xml()
        web_xml_data = File.readlines(self.web_xml_path()).map do |line|
          if line =~ /#{web_xml_token}/
            template = File.open("#{@config.resources_dir()}/jira_cas_web.xml") { |f| f.read() }
            line + ERB.new(template).result(@config.send(:binding))
          else
            line
          end
        end

        File.open(self.web_xml_path(), "w") do |io|
          web_xml_data.each { |line| io.puts(line) }
        end
      end

    end
  end
end