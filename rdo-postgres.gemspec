# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rdo/postgres/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["d11wtq"]
  gem.email         = ["chris@w3style.co.uk"]
  gem.description   = "Provides access to PostgreSQL using the RDO interface"
  gem.summary       = "PostgreSQL Driver for RDO"
  gem.homepage      = "https://github.com/d11wtq/rdo-postgres"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rdo-postgres"
  gem.require_paths = ["lib"]
  gem.version       = RDO::Postgres::VERSION
  gem.extensions    = ["ext/rdo_postgres/extconf.rb"]

  gem.add_runtime_dependency "rdo", ">= 0.0.1"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rake-compiler"
end
