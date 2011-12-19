
module UcbDeployer
  class ConfluenceDeployer < Deployer
    
    def initialize(config_file = "#{ENV['HOME']}/.ucb_deployer/config/confluence/deploy.yml")
      debug("Using config file: #{config_file}")
      debug("")
      load_config(config_file)
    end
    
    def export()
      UcbDeployer.debug("Exporting from: #{svn_project_url}/confluence-#{version}")
      Dir.chdir("#{build_dir}") do
        FileUtils.rm_rf("#{build_dir}/src")
        `svn export #{svn_project_url}/confluence-#{version}`
        FileUtils.mv("confluence-#{version}", "src")
      end
      $stdout.puts("Export Completed")
    end
    
    def configure()
      config_web_xml()
      config_seraph_config_xml()
      config_confluence_init_properties()
      config_xwork_xml()
      reshuffle_jars()
    end

    def build()
      Dir.chdir("#{build_dir}/src") do
        `sh #{build_dir}/src/build.sh`
      end
    end

    def deploy()
      if File.exists?("#{deploy_dir}/#{war_name}")
        FileUtils.rm_rf(Dir["#{deploy_dir}/#{war_name}"])
      end

      FileUtils.mkdir("#{deploy_dir}/#{war_name}")
      FileUtils.mv("#{build_dir}/src/dist/confluence-#{version}.war",
                   "#{deploy_dir}/#{war_name}/#{war_name}.war")

      `cd #{deploy_dir}/#{war_name}/ && jar -xvf #{war_name}.war`
      FileUtils.rm("#{deploy_dir}/#{war_name}/#{war_name}.war")
    end

    def rollback()
    end

    def svn_username()
      @svn_username || "app_relmgt"
    end
    
    def svn_base_url()
      @svn_base_url || "svn.berkeley.edu/svn/ist-svn/berkeley/projects/ist/as/webapps/confluence_archives"
    end
    
    ##
    # Shortcut to confluence web.xml file
    #
    def web_xml()
      "#{build_dir}/src/confluence/WEB-INF/web.xml"
    end
    
    ##
    # Shortcut to confluence seraph-config.xml file
    #
    def seraph_config_xml()
      "#{build_dir}/src/confluence/WEB-INF/classes/seraph-config.xml"
    end
    
    ##
    # Shortcut to confluence confluence-init.properties file
    #
    def confluence_init_properties()
      "#{build_dir}/src/confluence/WEB-INF/classes/confluence-init.properties"
    end
    
    def web_xml_token()
      "<!-- Uncomment the following to disable the space export long running task. -->"
    end
    
    def seraph_config_xml_token()
      "com.atlassian.confluence.user.ConfluenceAuthenticator"
    end
    
    def cas_authenticator_class()
      "org.soulwing.cas.apps.atlassian.ConfluenceCasAuthenticator"
    end
    
    ##
    # Updates the confluence web.xml file with the soulwing (CAS library)
    # authentication configuration
    #
    def config_web_xml()
      web_xml = File.readlines(self.web_xml)
      
      web_xml = web_xml.map do |line|
        if line =~ /#{web_xml_token}/
          template = File.open("#{DEPLOYER_HOME}/resources/confluence_cas_web.xml") { |f| f.read }
          ERB.new(template).result(self.send(:binding))
        else
          line
        end
      end
      
      File.open(self.web_xml, "w") do |io|
        web_xml.each { |line| io.puts(line) }
      end
    end

    ##
    # Updates the confluence seraph_config.xml file with the soulwing
    # authenticator.
    #
    def config_seraph_config_xml()
      seraph_xml = File.readlines(self.seraph_config_xml)
      
      seraph_xml = seraph_xml.map do |line|
        if m = /(#{Regexp.quote(seraph_config_xml_token)})/.match(line)
          debug(m[0])
          debug("#{m.pre_match}#{cas_authenticator_class}#{m.post_match}")
          "#{m.pre_match}#{cas_authenticator_class}#{m.post_match}"
        else
          line
        end
      end
      
      File.open(self.seraph_config_xml, "w") do |io|
        seraph_xml.each { |line| io.puts(line) }
      end
    end
    
    ##
    # Sets the confluence.home property in the file: confluence-init.properties.
    #
    def config_confluence_init_properties()
      File.open(self.confluence_init_properties, "w") do |io|
        io.puts("confluence.home=#{data_dir}")
      end
    end
    
    ##
    # Shortcut to xwork.xml file
    #
    def xwork_xml()
      "#{build_dir}/src/confluence/WEB-INF/classes/xwork.xml"
    end
    
    ##
    # Alter xwork.xml so soulwing authenticator works with CAS
    #
    def config_xwork_xml()
      template = File.open("#{UcbDeployer::RESOURCES_DIR}/xwork.xml") { |f| f.read }
      xml = ERB.new(template).result(self.send(:binding))
      FileUtils.touch(xwork_xml())
      File.open(xwork_xml(), "w") { |io| io.puts(xml) }
    end
      
    ##
    # Remove application jars that have been installed at the container level.
    #
    def reshuffle_jars()
      FileUtils.cp(Dir["#{UcbDeployer::RESOURCES_DIR}/soulwing-casclient-*"],
                   "#{build_dir}/src/confluence/WEB-INF/lib/")
      # Remove the jars that are installed at the container level
      ["postgresql", "activation", "mail"].each do |jar|
        FileUtils.rm_rf(Dir["#{build_dir}/src/confluence/WEB-INF/lib/#{jar}-*"])
      end
    end
  end
end

