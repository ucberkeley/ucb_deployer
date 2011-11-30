require File.expand_path("../lib/ucb_deployer/version", __FILE__)


Gem::Specification.new do |s|  
  s.name        = "ucb_deployer"  
  s.version     = UcbDeployer::VERSION  
  s.platform    = Gem::Platform::RUBY  
  s.authors     = ["Steven Hansen"]  
  s.email       = ["runner@berkeley.edu"]  
  s.homepage    = ""  
  s.summary     = %q{Tool for deploying Confluence and JIRA war files to tomcat}
  s.description = %q{Tool for deploying Confluence and JIRA war files to tomcat}

  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md"]
  s.rdoc_options = ["--main", "README.md"]
  s.rubyforge_project = "ucb_deployer"  
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = Dir["spec/**/**"]
  s.executables   = ["ucb_deploy"]
  s.require_paths = ["lib"]

  s.add_runtime_dependency(%q<rake>, ["= 0.8.7"])

  s.add_development_dependency(%q<rspec>, ["= 1.3.0"])
  s.add_development_dependency(%q<rcov>, [">= 0.9.9"])
  s.add_development_dependency(%q<diff-lcs>, [">= 1.1.2"])
  s.add_development_dependency(%q<ruby-debug>, [">= 0.10.4"])
end
