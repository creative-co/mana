# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mana/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ilia Ablamonov, Cloud Castle Inc."]
  gem.email         = ["ilia@flamefork.ru"]
  gem.description   = "Configuration management with Chef & Capistrano"
  gem.summary       = "Configuration management with Chef & Capistrano"
  gem.homepage      = "https://github.com/cloudcastle/mana"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "mana"
  gem.require_paths = ["lib"]
  gem.version       = Mana::VERSION
end
