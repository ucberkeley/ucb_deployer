require File.dirname(__FILE__) + '/../spec_helper'

describe UcbDeployer::ConfluenceDeployer do
  
  before(:each) do
    @deploy_file = File.expand_path(File.dirname(__FILE__) + '/../fixtures/confluence/deploy.yml')
    @bad_deploy_file = File.expand_path(File.dirname(__FILE__) + '/../fixtures/confluence/bad_deploy.yml')    
    @cdep = UcbDeployer::ConfluenceDeployer.new(@deploy_file)
  end
  
  def test_build_dir()
    "#{TEST_BUILD_DIR}/confluence"
  end
  
  describe "#load_config" do
    it "should load configuration options" do
      @cdep.build_dir.should == "/path/to/build_dir/confluence"
      @cdep.deploy_dir.should == "/path/to/deploy_dir"
      @cdep.war_name.should == "war_name"
      @cdep.svn_project_url.should == "svn+ssh://svn@code-qa.berkeley.edu/istas/confluence_archives/tags"
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
      lines.any? { |l| l =~ /<\?xml version="1\.0" encoding="UTF-8"\?>/ }.should be_true
      lines.any? { |l| l =~ /<web-app>/ }.should be_true
      lines.any? { |l| l =~ /#{@cdep.cas_server_url}/ }.should be_true
      lines.any? { |l| l =~ /#{@cdep.cas_service_url}/ }.should be_true
      lines.any? { |l| l =~ /<\/web-app>/ }.should be_true            
    end
  end
  
  describe "#config_xwork_xml" do
    it "should create and configure the xwork.xml file" do
      @cdep.build_dir = test_build_dir
      
      @cdep.config_xwork_xml      
      File.exists?(@cdep.xwork_xml).should be_true
      lines = File.readlines(@cdep.xwork_xml)
      lines.any? { |l| l =~ /<xwork>/ }.should be_true
      lines.any? { |l| l =~ /#{@cdep.cas_server_url}\/logout/ }.should be_true
      lines.any? { |l| l =~ /<\/xwork>/ }.should be_true            
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
      lines.any? { |l| l =~ /<security-config>/ }.should be_true
      lines.any? { |l| l =~ /#{Regexp.quote(@cdep.cas_authenticator_class)}/ }.should be_true
      lines.any? { |l| l =~ /<\/security-config>/ }.should be_true            
    end
  end


  describe "#config_confluence_init_props" do
    it "should configure confluence-init.properties" do
      @cdep.build_dir = test_build_dir
      # just checking if spec_helper did the right
      File.exists?(@cdep.confluence_init_properties).should be_true

      @cdep.config_confluence_init_properties
      File.exists?(@cdep.confluence_init_properties).should be_true
      lines = File.readlines(@cdep.confluence_init_properties)
      lines.any? { |l| l =~ /confluence.home=#{@cdep.data_dir}/ }.should be_true
    end
  end
  
  
  describe "#reshuffle_jars" do
    it "should work" do
      @cdep.build_dir = test_build_dir()
      @cdep.reshuffle_jars()
      Dir["#{@cdep.build_dir}/src/confluence/WEB-INF/lib/soulwing-casclient-*"].should_not be_empty
      ["postgresql", "activation", "mail"].each do |jar|
        Dir["#{@cdep.build_dir}/src/confluence/WEB-INF/lib/#{jar}-*"].should be_empty
      end
    end
  end

  
  describe "#build" do
    it "should work" do
      @cdep.build_dir = test_build_dir
      @cdep.should_receive("`").with("sh #{@cdep.build_dir}/src/build.sh")
      @cdep.build
    end
  end
  

  describe "#export" do
    it "should work" do
      cdep = UcbDeployer::ConfluenceDeployer.new(@deploy_file)
      cdep.build_dir = test_build_dir
      cdep.version = "3.2.1_01"
      arg = "svn export #{cdep.svn_project_url}/confluence-#{cdep.version}"
      cdep.should_receive("`").with(arg).and_return(nil)
      FileUtils.should_receive("mv")
      cdep.export()
    end
  end
  
end
