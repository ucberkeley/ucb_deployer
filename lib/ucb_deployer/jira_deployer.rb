
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
      self.config_web_xml()
      self.config_seraph_config_xml()
      self.config_entityengine_xml()
      self.config_jira_application_properties()
      self.config_ist_banner()
      self.reshuffle_jars()
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

    def cas_logout_url()
      "/casLogout.action"
    end

    ##
    # Shortcut to jira web.xml file
    #
    def web_xml()
      "#{self.build_dir()}/src/webapp/WEB-INF/web.xml"
    end
    
    def web_xml_token()
      "<!--This filter is used to determine is there are any Application Errors before any pages are accessed"
    end
    
    ##
    # Updates the jira web.xml file with the soulwing (CAS library)
    # authentication configuration
    #
    def config_web_xml()
      web_xml = File.readlines(self.web_xml()).map do |line|
        if line =~ /#{web_xml_token}/
          template = File.open("#{DEPLOYER_HOME}/resources/jira_cas_web.xml") { |f| f.read() }
          line + ERB.new(template).result(self.send(:binding))
        else
          line
        end
      end
      
      File.open(self.web_xml(), "w") do |io|
        web_xml.each { |line| io.puts(line) }
      end      
    end
    
    ##
    # Shortcut to jira entityengine.xml file
    #
    def entityengine_xml()
      "#{self.build_dir()}/src/edit-webapp/WEB-INF/classes/entityengine.xml"
    end
    
    def entityengine_xml_db_token()
      "field-type-name=\"hsql\""
    end
    
    def entityengine_xml_schema_token()
      "schema-name=\"PUBLIC\""
    end
    
    def entityengine_db()
      "field-type-name=\"postgres72\""
    end
    
    def entityengine_schema()
      "schema-name=\"jira_app\""
    end
    
    ##
    # Updates the jira entityengine.xml file with the correct database configs
    #
    def config_entityengine_xml()
      ee_xml = File.readlines(self.entityengine_xml()).map do |line|
        if m = /(#{Regexp.quote(self.entityengine_xml_db_token())})/.match(line)
          self.debug(m[0])
          new_str = "#{m.pre_match}#{entityengine_db}#{m.post_match}"
          self.debug(new_str)
          new_str
        elsif m = /(#{Regexp.quote(self.entityengine_xml_schema_token())})/.match(line)
          self.debug(m[0])
          new_str = "#{m.pre_match}#{self.entityengine_schema()}#{m.post_match}"
          self.debug(new_str)
          new_str
        else
          line
        end
      end
      
      File.open(self.entityengine_xml(), "w") do |io|
        ee_xml.each { |line| io.puts(line) }
      end
    end
    
    ##
    # Shortcut to jira seraph-config.xml file
    #
    def seraph_config_xml()
      "#{self.build_dir()}/src/webapp/WEB-INF/classes/seraph-config.xml"
    end
    
    def seraph_config_xml_auth_class_token()
      "com.atlassian.jira.security.login.JiraOsUserAuthenticator"
    end
    
    def seraph_config_xml_logout_url_token()
      "/secure/Logout!default.jspa"
    end
    
    def cas_authenticator_class()
      "org.soulwing.cas.apps.atlassian.JiraCasAuthenticator"
    end
    
    ##
    # Updates the jira seraph_config.xml file with the soulwing
    # authenticator.
    #
    def config_seraph_config_xml()
      seraph_xml = File.readlines(self.seraph_config_xml()).map do |line|
        if m = /(#{Regexp.quote(self.seraph_config_xml_auth_class_token())})/.match(line)
          self.debug(m[0])
          new_str = "#{m.pre_match}#{self.cas_authenticator_class()}#{m.post_match}"
          self.debug(new_str)
          new_str
        elsif m = /(#{Regexp.quote(self.seraph_config_xml_logout_url_token())})/.match(line)
          self.debug(m[0])
          new_str = "#{m.pre_match}#{self.cas_server_url()}/logout#{m.post_match}"
          self.debug(new_str)
          new_str
        else
          line
        end
      end
      
      File.open(self.seraph_config_xml(), "w") do |io|
        seraph_xml.each { |line| io.puts(line) }
      end
    end
    
    ##
    # Shortcut to jira-application.properties file
    #
    def jira_application_properties()
      "#{self.build_dir()}/src/edit-webapp/WEB-INF/classes/jira-application.properties"
    end
    
    def jira_home_token()
      "jira.home ="
    end
    
    ##
    # Sets the jira.home property in the file: jira-application.properties.
    #
    def config_jira_application_properties()
      jira_props = File.readlines(self.jira_application_properties()).map do |line|
        if m = /(#{Regexp.quote(jira_home_token)})/.match(line)
          self.debug(m[0])
          new_str = "#{self.jira_home_token()} #{self.data_dir()}"
          self.debug(new_str)
          new_str
        else
          line
        end
      end
      
      File.open(self.jira_application_properties(), "w") do |io|
        jira_props.each { |line| io.puts(line) }
      end
    end

    ##
    # Places IST banner jpg in imaages directory
    #
    def config_ist_banner()
      FileUtils.cp("#{UcbDeployer::RESOURCES_DIR}/ist_banner.jpg",
                   "#{self.build_dir()}/src/webapp/images/")
    end
    
    ##
    # Remove jars from WEB-INF/lib that have been installed at the container
    # level to avoid conflicts.
    #
    def reshuffle_jars()
      FileUtils.mkdir_p("#{self.build_dir()}/src/edit-webapp/WEB-INF/lib/")
      FileUtils.cp(Dir["#{UcbDeployer::RESOURCES_DIR}/soulwing-casclient-*"],
                   "#{self.build_dir()}/src/edit-webapp/WEB-INF/lib/")
      # These have been placed in $CATALINA_HOME/lib
      ["mail", "activation", "javamail", "commons-logging", "log4j"].each do |jar|
        FileUtils.rm_rf(Dir["#{self.build_dir()}/src/webapp/WEB-INF/lib/#{jar}-*"])
      end
    end

  end
end

