require 'yaml'
require 'net/http'
require 'erb'
require 'ucb_deployer/deployer'
require 'ucb_deployer/confluence_deployer'
require 'ucb_deployer/jira_deployer'

require 'ucb_deployer/config_tasks/jira/config_cas_auth'
require 'ucb_deployer/config_tasks/jira/config_app_properties'
require 'ucb_deployer/config_tasks/jira/config_jira_config_properties'
require 'ucb_deployer/config_tasks/jira/config_ist_banner'
require 'ucb_deployer/config_tasks/jira/remove_conflicting_jar_files'


module UcbDeployer
  class ConfigError < RuntimeError; end
  
  DEPLOYER_HOME = File.expand_path(File.dirname(__FILE__) + '/..') unless defined?(DEPLOYER_HOME)
  RESOURCES_DIR = File.expand_path("#{DEPLOYER_HOME}/resources") unless defined?(RESOURCES_DIR)  
  

  ##
  # Valid options are
  #
  # @param [Symbol|String] valid __app_name__ values are: "confluence", "jira"
  # @raise [UcbDeployer::ConfigError] raises if invalid value is used for __app_name__
  # @return [UcbDeployer::Deployer]
  #
  def self.factory(app_name)
    begin
      if app_name == :confluence
        return UcbDeployer::ConfluenceDeployer.new()
      elsif app_name == :jira
        return UcbDeployer::JiraDeployer.new()
      end
    rescue => e
      raise(UcbDeployer::ConfigError, e)
    end
    
    raise(ConfigError, "Unrecognized app_name: #{app_name}")
  end

  def self.debug(str)
    if debug_mode
      $stdout.puts(str)
    end
  end
  
  def self.info(str)
    $stdout.puts(str)
  end
  
  def self.debug_mode()
    @debug_mode || false
  end

  def self.debug_mode=(bool)
    @debug_mode = bool
  end
end
