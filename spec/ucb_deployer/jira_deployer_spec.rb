require File.dirname(__FILE__) + '/../spec_helper'


describe UcbDeployer::JiraDeployer do
  before(:each) do
    @deploy_file = File.expand_path(File.dirname(__FILE__) + '/../fixtures/jira/deploy.yml')
    @bad_deploy_file = File.expand_path(File.dirname(__FILE__) + '/../fixtures/jira/bad_deploy.yml')    
    @cdep = UcbDeployer::JiraDeployer.new(@deploy_file)
  end
  
  def test_build_dir()
    "#{TEST_BUILD_DIR}/jira"
  end
  
  
  describe "#load_config" do
    it "should load configuration options" do
      @cdep.build_dir.should == "/path/to/build_dir/jira"
      @cdep.deploy_dir.should == "/path/to/deploy_dir"
      @cdep.war_name.should == "war_name"
      @cdep.svn_project_url.should == "svn.berkeley.edu/svn/ist-svn/berkeley/projects/ist/as/webapps/jira_archives/tags"
    end

    it "should raise error for invalid config options" do
      lambda { @cdep.load_config(@bad_deploy_file) }.should raise_error(UcbDeployer::ConfigError)
    end
  end
  
  
  describe "#config_web_xml" do
    it "should configure souldwing (CAS auth) in web.xml" do
      @cdep.build_dir = test_build_dir
      # just checking if spec_helper did the right
      File.exists?(@cdep.web_xml).should be_true

      @cdep.config_web_xml
      File.exists?(@cdep.web_xml).should be_true
      lines = File.readlines(@cdep.web_xml)
      lines.grep(/<\?xml version="1\.0"\?>/).should be_true
      lines.grep(/^<web-app /).should be_true
      lines.grep(/#{@cdep.cas_server_url}/).should have(1).record
      lines.grep(/#{@cdep.cas_service_url}/).should have(1).record
      lines.grep(/<\/web-app>/).should be_true            
    end
  end
  
  
  describe "#config_seraph_config_xml" do
    it "should configure the soulwing (CAS) authenticator in seraph_config.xml" do
      @cdep.build_dir = test_build_dir
      # just checking if spec_helper did the right
      File.exists?(@cdep.seraph_config_xml).should be_true

      @cdep.config_seraph_config_xml
      File.exists?(@cdep.seraph_config_xml).should be_true
      lines = File.readlines(@cdep.seraph_config_xml)
      lines.grep(/<security-config>/).should be_true
      lines.grep(/#{Regexp.quote(@cdep.cas_authenticator_class)}/).should have(1).record
      lines.grep(/#{Regexp.quote(@cdep.cas_server_url)}\/logout/).should have(1).record
      lines.grep(/<\/security-config>/).should be_true            
    end
  end
  

  describe "#config_entityengine_xml" do
    it "should configure the postgres72 db option in entityengine.xml" do
      @cdep.build_dir = test_build_dir
      # just checking if spec_helper did the right
      File.exists?(@cdep.entityengine_xml).should be_true

      @cdep.config_entityengine_xml
      File.exists?(@cdep.entityengine_xml).should be_true
      lines = File.readlines(@cdep.entityengine_xml)
      lines.any? { |l| l =~ /<entity-config>/ }.should be_true
      lines.any? { |l| l =~ /#{Regexp.quote(@cdep.entityengine_db)}/ }.should be_true
      lines.any? { |l| l =~ /#{Regexp.quote(@cdep.entityengine_schema)}/ }.should be_true      
      lines.any? { |l| l =~ /<\/entity-config>/ }.should be_true            
    end
  end
  
  describe "#config_jira_application_properties" do
    it "should configure jira.home in the jira-application.properties file" do
      @cdep.build_dir = test_build_dir
      # just checking if spec_helper did the right
      File.exists?(@cdep.jira_application_properties).should be_true
      
      @cdep.config_jira_application_properties
      File.exists?(@cdep.jira_application_properties).should be_true
      lines = File.readlines(@cdep.jira_application_properties)
      lines.any? { |l| l =~ /# JIRA HOME/ }.should be_true
      lines.any? { |l| l =~ /# JIRA SECURITY SETTINGS/ }.should be_true
      lines.any? { |l| l =~ /#{Regexp.quote(@cdep.jira_home_token + ' ' + @cdep.data_dir)}/ }.should be_true      
      lines.any? { |l| l =~ /# NOTES FOR DEVELOPERS/ }.should be_true            
    end
  end
  
  describe "#config_ist_banner" do
    it "should place ist_banner.jpg in webapps" do
      @cdep.build_dir = test_build_dir()
      @cdep.config_ist_banner()
      File.exists?("#{@cdep.build_dir}/src/webapp/images/ist_banner.jpg").should be_true
    end
  end
  
  describe "#reshuffle_jars" do
    it "should work" do
      @cdep.build_dir = test_build_dir()
      @cdep.reshuffle_jars()
      Dir["#{@cdep.build_dir}/src/edit-webapp/WEB-INF/lib/soulwing-casclient-*"].should_not be_empty
      ["activation", "javamail", "commons-logging", "log4j"].each do |lib|
        Dir["#{@cdep.build_dir}/src/edit-webapp/WEB-INF/lib/#{lib}-*"].should be_empty
      end
    end
  end

  
  describe "#build" do
    it "should work" do
      @cdep.build_dir = test_build_dir()
      @cdep.should_receive("`").with("sh #{@cdep.build_dir}/src/build.sh")
      @cdep.build()
    end
  end
  

  describe "#export" do
    it "should work" do
      cdep = UcbDeployer::JiraDeployer.new(@deploy_file)
      cdep.build_dir = test_build_dir()
      cdep.version = "3.2.1_01"
      arg = "svn export svn+ssh://#{cdep.svn_username}@#{cdep.svn_project_url}/jira-#{cdep.version}"
      cdep.should_receive("`").with(arg).and_return(nil)
      FileUtils.should_receive("mv")
      cdep.export()
    end
  end
end
