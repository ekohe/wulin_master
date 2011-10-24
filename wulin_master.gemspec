# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "wulin_master/version"

Gem::Specification.new do |s|
  s.name        = "wulin_master"
  s.version     = WulinMaster::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["TODO: Write your name"]
  s.email       = ["TODO: Write your email address"]
  s.homepage    = "http://rubygems.org/gems/wulin_master"
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "wulin_master"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'jquery-rails'
  s.add_development_dependency "rspec-rails", "~> 2.6"
  s.add_development_dependency "ZenTest"
  s.add_development_dependency "autotest-rails"
  s.add_development_dependency "spork", "~> 0.9.0.rc9"
  s.add_development_dependency "generator_spec"
end