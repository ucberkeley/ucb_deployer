require File.dirname(__FILE__) + '/../spec_helper'


describe UcbDeployer::JiraDeployer do
  before(:each) do
    @deploy_file = File.expand_path(File.dirname(__FILE__) + '/../fixtures/jira/deploy.yml')
    @bad_deploy_file = File.expand_path(File.dirname(__FILE__) + '/../fixtures/jira/bad_deploy.yml')
    @jdep = UcbDeployer::JiraDeployer.new(@deploy_file)
  end

  def test_build_dir()
    "#{TEST_BUILD_DIR}/jira"
  end


  describe "configure()" do
    it "should load configuration options" do
      @jdep.build_dir.should == "/path/to/build_dir/jira"
      @jdep.deploy_dir.should == "/path/to/deploy_dir"
      @jdep.war_name.should == "war_name"
      @jdep.svn_project_url.should == "svn+ssh://svn@code.berkeley.edu/istas/jira_archives/tags"
    end

    it "should raise error for invalid config options" do
      lambda { @jdep.load_config(@bad_deploy_file) }.should raise_error(UcbDeployer::ConfigError)
    end

    it "should configure souldwing (CAS auth) in web.xml" do
      @jdep.build_dir = test_build_dir
      # just checking if spec_helper did the right
      File.exists?(@jdep.web_xml).should be_true

      @jdep.configure()
      File.exists?(@jdep.web_xml).should be_true
      lines = File.readlines(@jdep.web_xml)
      lines.grep(/<\?xml version="1\.0"\?>/).should be_true
      lines.grep(/^<web-app /).should be_true
      lines.grep(/#{@jdep.cas_server_url}/).should have(1).record
      lines.grep(/#{@jdep.cas_service_url}/).should have(1).record
      lines.grep(/<\/web-app>/).should be_true
    end

    it "should configure the soulwing (CAS) authenticator in seraph_config.xml" do
      @jdep.build_dir = test_build_dir
      # just checking if spec_helper did the right
      File.exists?(@jdep.seraph_config_xml).should be_true

      @jdep.configure()
      File.exists?(@jdep.seraph_config_xml).should be_true
      lines = File.readlines(@jdep.seraph_config_xml)
      lines.grep(/<security-config>/).should be_true
      lines.grep(/#{Regexp.quote(@jdep.cas_authenticator_class)}/).should have(1).record
      lines.grep(/#{Regexp.quote(@jdep.cas_server_url)}\/logout/).should have(1).record
      lines.grep(/<\/security-config>/).should be_true
    end

    it "should configure the postgres72 db option in entityengine.xml" do
      @jdep.build_dir = test_build_dir
      # just checking if spec_helper did the right
      File.exists?(@jdep.entityengine_xml).should be_true

      @jdep.configure()
      File.exists?(@jdep.entityengine_xml).should be_true
      lines = File.readlines(@jdep.entityengine_xml)
      lines.any? { |l| l =~ /<entity-config>/ }.should be_true
      lines.any? { |l| l =~ /#{Regexp.quote(@jdep.entityengine_db)}/ }.should be_true
      lines.any? { |l| l =~ /#{Regexp.quote(@jdep.entityengine_schema)}/ }.should be_true
      lines.any? { |l| l =~ /<\/entity-config>/ }.should be_true
    end

    context "jira-application.properties file" do
      it "should configure jira.home" do
        @jdep.build_dir = test_build_dir()
        # just checking if spec_helper did the right
        File.exists?(@jdep.jira_application_properties).should be_true

        @jdep.configure()
        File.exists?(@jdep.jira_application_properties).should be_true
        lines = File.readlines(@jdep.jira_application_properties)
        lines.any? { |l| l =~ /# JIRA HOME/ }.should be_true
        lines.any? { |l| l =~ /# JIRA SECURITY SETTINGS/ }.should be_true
        lines.any? { |l| l =~ /#{Regexp.quote(@jdep.jira_home_token + ' ' + @jdep.data_dir)}/ }.should be_true
        lines.any? { |l| l =~ /# NOTES FOR DEVELOPERS/ }.should be_true
      end

      it "should configure jira.projectkey.pattern" do
        @jdep.build_dir = test_build_dir()
        # just checking if spec_helper did the right
        File.exists?(@jdep.jira_application_properties()).should be_true

        @jdep.configure()
        File.exists?(@jdep.jira_application_properties).should be_true
        lines = File.readlines(@jdep.jira_application_properties)
        lines.any? { |l| l =~ /# JIRA HOME/ }.should be_true
        lines.any? { |l| l =~ /# JIRA SECURITY SETTINGS/ }.should be_true
        lines.any? { |l| l =~ /#{Regexp.quote(@jdep.jira_projectkey_token() + ' ' + "([A-Z][A-Z0-9]+)")}/ }.should be_true
        lines.any? { |l| l =~ /# NOTES FOR DEVELOPERS/ }.should be_true
      end
    end

    it "should place ist_banner.jpg in webapps" do
      @jdep.build_dir = test_build_dir()
      @jdep.configure()
      File.exists?("#{@jdep.build_dir}/src/webapp/images/ist_banner.jpg").should be_true
    end

    it "should reshuffle jar files" do
      @jdep.build_dir = test_build_dir()
      @jdep.configure()
      Dir["#{@jdep.build_dir}/src/edit-webapp/WEB-INF/lib/soulwing-casclient-*"].should_not be_empty
      ["activation", "javamail", "commons-logging", "log4j"].each do |lib|
        Dir["#{@jdep.build_dir}/src/edit-webapp/WEB-INF/lib/#{lib}-*"].should be_empty
      end
    end
  end

  describe "#build" do
    it "should build the the war" do
      @jdep.build_dir = test_build_dir()
      @jdep.should_receive("`").with("sh #{@jdep.build_dir}/src/build.sh")
      @jdep.build()
    end
  end

  describe "#export" do
    it "should export the code from svn" do
      jdep = UcbDeployer::JiraDeployer.new(@deploy_file)
      jdep.build_dir = test_build_dir()
      jdep.version = "3.2.1_01"
      arg = "svn export #{jdep.svn_project_url}/jira-#{jdep.version}"
      jdep.should_receive("`").with(arg).and_return(nil)
      FileUtils.should_receive("mv")
      jdep.export()
    end
  end
end
