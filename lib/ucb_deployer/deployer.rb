
module UcbDeployer
  ##
  # @author Steven Hansen
  #
  # @abstract Subclass and override {#export, #build, #configure, #deploy,
  # #rollback} to implement a custom UcbDeployer class
  #
  class Deployer
    
    CONFIG_OPTIONS = [
      :build_dir,
      :deploy_dir,
      :war_name,
      :cas_service_url,
      :cas_server_url,
      :data_dir,
      :maintenance_file_dir,                      
      :svn_project_url,
    ]
    
    attr_accessor *CONFIG_OPTIONS
    attr_accessor :version, :debug_mode
    
    
    def export()
      raise NotImplementedError
    end
    
    def configure()
      raise NotImplementedError
    end

    def build()
      raise NotImplementedError
    end

    def rollback()
      raise NotImplementedError
    end
    
    def deploy()
      raise NotImplementedError
    end

    ##
    # Configuration options are:
    #
    # +build_dir+
    # +deploy_dir+
    # +war_name+
    # +svn_project_url+
    # +cas_service_url+
    # +cas_server_url+
    # +maintenance_file_dir+    
    # +data_dir+  
    #
    def load_config(config_file)
      if !(hash = YAML.load_file(config_file))
        raise(ConfigError, "Config file [#{config_file}] contains no options.")
      end
      
      debug("Config options:")
      debug("")      
      hash.each do |key, val|
        debug("#{key}: #{val}")      
        if CONFIG_OPTIONS.include?(key.to_sym)
          self.send("#{key}=", val)
        else
          raise(ConfigError, "Unrecognized Option: #{key}")
        end
      end
    end

    def self.deployer_home()
      ::UcbDeployer::DEPLOYER_HOME
    end

    def self.resources_dir()
      ::UcbDeployer::RESOURCES_DIR
    end

    def debug(str)
      UcbDeployer.debug(str)
    end
    
    def info(str)
      UcbDeployer.info(str)
    end
    
    def disable_web()
      return unless maintenance_file_dir()
      maint_start = Time.now.strftime("%m-%d-%Y %H:%M:%S")
      template = ERB.new(maintenance_template)
      File.open("#{maintenance_file_dir}/maintenance.html", "w") do |f|
        f.puts template.result(binding)
      end
    end
    
    def enable_web()
      return unless maintenance_file_dir()      
      FileUtils.rm("#{maintenance_file_dir}/maintenance.html")
    end
    
    def maintenance_template()
      %q{
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">

<head>
  <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
  <title>Site Maintenance</title>
  <style type="text/css">
  body { background-color: #fff; color: #666; text-align: center; font-family: arial, sans-serif; }
  div.dialog {
  width: 35em;
  padding: 0 3em;
  margin: 3em auto 0 auto;
  border: 1px solid #ccc;
  border-right-color: #999;
  border-bottom-color: #999;
  }
  h1 { font-size: 100%; color: #f00; line-height: 1.5em; }
  </style>
</head>

<body>
  <div class="dialog">
    <h1>Site Maintenance</h1>
    <p>
        The site is down for maintenance as of: <strong><%= maint_start %></strong> <br/>
        it should be available shortly.
    </p>
  </div>
</body>
</html>
}
    end
    
  end
end
