##
# Remove jars from WEB-INF/lib that have been installed at the container
# level to avoid conflicts.
#
module UcbDeployer::ConfigTasks
  module Jira
    class RemoveConflictingJarFiles

      def initialize(config)
        @config = config
      end

      def execute()
        FileUtils.mkdir_p("#{@config.build_dir()}/src/edit-webapp/WEB-INF/lib/")
        FileUtils.cp(Dir["#{UcbDeployer::RESOURCES_DIR}/soulwing-casclient-*"],
                     "#{@config.build_dir()}/src/edit-webapp/WEB-INF/lib/")

        # These have been placed in $CATALINA_HOME/lib
        ["mail", "activation", "javamail", "commons-logging", "log4j"].each do |jar_file|
          FileUtils.rm_rf(Dir["#{@config.build_dir()}/src/webapp/WEB-INF/lib/#{jar_file}-*"])
        end
      end

    end
  end
end