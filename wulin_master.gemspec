# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "wulin_master/version"

Gem::Specification.new do |s|
  s.name        = "wulin_master"
  s.version     = WulinMaster::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ekohe"]
  s.email       = ["dev@ekohe.com"]
  s.homepage    = "http://rubygems.org/gems/wulin_master"
  s.summary     = %q{WulinMaster is a framework}
  s.description = %q{WulinMaster is a framework}

  s.rubyforge_project = "wulin_master"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'jquery-rails', '4.0.3'
  s.add_dependency 'jquery-ui-rails', '5.0.5'
  s.add_dependency 'haml-rails'
  s.add_dependency 'compass', '1.0.3'
  s.add_development_dependency "rspec-rails", "~> 2.8"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-spork"
  s.add_development_dependency "spork", "~> 0.9.2"
  s.add_development_dependency "generator_spec"
end