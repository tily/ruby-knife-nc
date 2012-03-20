# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-nc/version"

Gem::Specification.new do |s|
  s.name        = "knife-nc"
  s.version     = Knife::Nc::VERSION
  s.has_rdoc = true
  s.authors     = ["tily"]
  s.email       = ["tidnlyam@gmail.com"]
  s.homepage = "https://github.com/tily/ruby-knife-nc"
  s.summary = "NIFTY Cloud Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ["README.md", "LICENSE" ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

end
