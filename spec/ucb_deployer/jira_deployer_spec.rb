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

    #it "should execute all the config tasks" do
    #  @jdep.configure()
    #end
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


describe UcbDeployer::ConfigTasks::Jira do
  before(:each) do
    @config = mock("config", {
        :resources_dir => UcbDeployer::RESOURCES_DIR,
        :build_dir => "#{TEST_BUILD_DIR}/jira",
        :cas_server_url => "THE CAS SERVER URL",
        :cas_service_url => "THE CAS SERVICE URL",
        :deployer_home => UcbDeployer::DEPLOYER_HOME,
        :data_dir => "#{TEST_BUILD_DIR}/jira"
    })
  end

  it "should configure cas authentication" do
    task = UcbDeployer::ConfigTasks::Jira::ConfigCasAuth.new(@config)
    task.execute()

    lines = File.readlines(task.seraph_config_path())
    lines.grep(/<security-config>/).should be_true
    lines.grep(/#{Regexp.quote(task.cas_authenticator_class())}/).should have(1).record
    lines.grep(/#{Regexp.quote(@config.cas_server_url())}\/logout/).should have(1).record
    lines.grep(/<\/security-config>/).should be_true

    lines = File.readlines(task.web_xml_path())
    lines.grep(/#{Regexp.quote(@config.cas_server_url())}/).should have(1).record
    lines.grep(/#{Regexp.quote(@config.cas_service_url())}/).should have(1).record
  end

  it "should remove conflicing jar file" do
    task = UcbDeployer::ConfigTasks::Jira::RemoveConflictingJarFiles.new(@config)
    task.execute()

    Dir["#{@config.build_dir}/src/edit-webapp/WEB-INF/lib/soulwing-casclient-*"].should_not be_empty
    ["activation", "javamail", "commons-logging", "log4j"].each do |lib|
      Dir["#{@config.build_dir}/src/edit-webapp/WEB-INF/lib/#{lib}-*"].should be_empty
    end
  end

  it "should configure the ist banner image" do
    task = UcbDeployer::ConfigTasks::Jira::ConfigIstBanner.new(@config)
    task.execute()

    File.exists?("#{@config.build_dir()}/src/webapp/images/ist_banner.jpg").should be_true
  end

  it "should configure the jira-config.properties file" do
    task = UcbDeployer::ConfigTasks::Jira::ConfigJiraConfigProperties.new(@config)
    task.execute()

    lines = File.readlines(task.jira_config_properties_path())
    lines.any? { |l| l =~ /#{Regexp.quote(task.projectkey_config())}/ }.should be_true
  end

  it "should configure the jira-application.properties file" do
    task = UcbDeployer::ConfigTasks::Jira::ConfigAppProperties.new(@config)
    task.execute()

    lines = File.readlines(task.jira_app_properties_path())
    lines.any? { |line|
      line =~ /#{Regexp.quote(task.jira_home_token() + ' ' + @config.data_dir)}/
    }.should be_true
  end
end