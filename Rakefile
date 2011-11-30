require 'bundler'  
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'

Bundler::GemHelper.install_tasks()

Spec::Rake::SpecTask.new("spec:rcov") do |t|
  t.spec_opts ||= []
  t.spec_opts << "--options" << "spec/spec.opts"
  t.rcov = true
end

Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_opts ||= []
  t.spec_opts << "--options" << "spec/spec.opts"
end

RCov::VerifyTask.new(:rcov => "spec:rcov") do |t|
  t.threshold = 100
end

