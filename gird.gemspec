# coding: utf-8

require File.join(%W[#{File.dirname(__FILE__)} lib gird version])

Gem::Specification.new do |spec|
  spec.name          = 'gird'
  spec.version       = Gird::VERSION
  spec.authors       = ['Ahmad Amireh']
  spec.email         = ['ahmad@algollabs.com']
  spec.summary       = %q{i18n phrase extractor.}
  spec.homepage      = 'https://github.com/amireh/gird'
  spec.license       = 'MIT'
  spec.description   = <<-DESCRIPTION
    Gird can scan a repository of JavaScript/JSX sources that use i18next for
    translating phrases, extract those phrases and build a JSON phrase bank
    which can be fed into i18nbeast for translators and developers to work with.
  DESCRIPTION

  spec.files         = Dir.glob("lib/**/*") + %w[ README.md LICENSE.txt ]
  spec.test_files    = spec.files.grep(%r{spec})
  spec.executables   = 'gird'
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 4.0'
  spec.add_dependency 'thor', '~> 0.19'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'guard', '~> 2.6'
  spec.add_development_dependency 'guard-rspec', '~> 4.2'
  spec.add_development_dependency 'terminal-notifier-guard', '~> 1.5'
end
