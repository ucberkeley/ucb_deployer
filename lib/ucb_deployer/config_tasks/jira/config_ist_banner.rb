##
# Places IST banner jpg in images directory
#
module UcbDeployer::ConfigTasks
  class ConfigIstBanner

    def initialize(config)
      @config = config
    end

    def execute()
      FileUtils.cp("#{UcbDeployer::RESOURCES_DIR}/ist_banner.jpg",
                   "#{@config.build_dir()}/src/webapp/images/")
    end

  end
end