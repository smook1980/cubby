# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cubby/version'

Gem::Specification.new do |spec|
  spec.name          = 'cubby'
  spec.version       = Cubby::VERSION
  spec.authors       = ['Shane Mook']
  spec.email         = ['smook@ncsasports.org']

  spec.summary       = 'Object store, like your cubby at school'
  spec.description   = 'Weak sauce will one day be stronger.'
  spec.homepage      = 'http:/aint.one'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lmdb'
  spec.add_runtime_dependency 'activemodel'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'msgpack'

  # Viable light weight faster alternative to Virtus?
  # I should try it sometime....
  # https://github.com/applift/fast_attributes
  # spec.add_runtime_dependency 'fast_attributes'
  # spec.add_runtime_dependency 'virtus'

  #spec.add_runtime_dependency 'rainbow'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'ffaker'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rubycritic'
  spec.add_development_dependency 'rubocop'
end
