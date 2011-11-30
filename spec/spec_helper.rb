require 'fileutils'
require 'rubygems'
require 'spec'
require 'pp'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'ucb_deployer'


TEST_BUILD_DIR = File.expand_path(File.dirname(__FILE__) + "/build") unless defined?(TEST_BUILD_DIR)


Spec::Runner.configure do |config|
  config.before(:all) do
    # puts "Running before(:all)"
    
    dir = TEST_BUILD_DIR
    pwd = File.expand_path(File.dirname(__FILE__))
    
    # setup confluence build dir
    FileUtils.mkdir_p("#{dir}/confluence/src/confluence/WEB-INF/classes")
    FileUtils.mkdir_p("#{dir}/confluence/src/confluence/WEB-INF/lib")
    FileUtils.touch("#{dir}/confluence/src/confluence/WEB-INF/lib/postgresql-1.3.3.jar")
    FileUtils.touch("#{dir}/confluence/src/confluence/WEB-INF/lib/mail-1.3.3.jar")
    FileUtils.touch("#{dir}/confluence/src/confluence/WEB-INF/lib/activation-1.3.3.jar")    
    
    FileUtils.cp("#{pwd}/fixtures/confluence/web.xml",
                 "#{dir}/confluence/src/confluence/WEB-INF")
    FileUtils.cp("#{pwd}/fixtures/confluence/seraph-config.xml",
                 "#{dir}/confluence/src/confluence/WEB-INF/classes")
    FileUtils.cp("#{pwd}/fixtures/confluence/confluence-init.properties",
                 "#{dir}/confluence/src/confluence/WEB-INF/classes")

    # setup jira build dir
    FileUtils.mkdir_p("#{dir}/jira/src/webapp/images")
    FileUtils.mkdir_p("#{dir}/jira/src/webapp/WEB-INF/classes")
    FileUtils.mkdir_p("#{dir}/jira/src/edit-webapp/WEB-INF/classes")    
    FileUtils.mkdir_p("#{dir}/jira/src/webapp/WEB-INF/lib")
    FileUtils.touch("#{dir}/jira/src/webapp/WEB-INF/lib/activation-1.0.2.jar")
    FileUtils.touch("#{dir}/jira/src/webapp/WEB-INF/lib/javamail-1.3.3.jar")
    FileUtils.touch("#{dir}/jira/src/webapp/WEB-INF/lib/commons-logging-1.3.3.jar")
    FileUtils.touch("#{dir}/jira/src/webapp/WEB-INF/lib/log4j-1.3.3.jar")
    
    FileUtils.cp("#{pwd}/fixtures/jira/web.xml",
                 "#{dir}/jira/src/webapp/WEB-INF")
    FileUtils.cp("#{pwd}/fixtures/jira/seraph-config.xml",
                 "#{dir}/jira/src/webapp/WEB-INF/classes")
    
    FileUtils.cp("#{pwd}/fixtures/jira/entityengine.xml",
                 "#{dir}/jira/src/edit-webapp/WEB-INF/classes")
    FileUtils.cp("#{pwd}/fixtures/jira/jira-application.properties",
                 "#{dir}/jira/src/edit-webapp/WEB-INF/classes")    
  end
  
  config.after(:all) do
    FileUtils.rm_rf("#{TEST_BUILD_DIR}/confluence")
    FileUtils.rm_rf("#{TEST_BUILD_DIR}/jira")    
  end
end
