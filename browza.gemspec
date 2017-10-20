# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'browza/version'

Gem::Specification.new do |spec|
  spec.name          = "browza"
  spec.version       = Browza::VERSION
  spec.authors       = ["H20Dragon"]
  spec.email         = ["h20dragon@outlook.com"]

  spec.summary       = %q{Lightweight Selenium Automation Framework - Command Based.}
  spec.description   = %q{Lightweight Selenium Automation Framework.}
  spec.homepage      = "http://github.com/h20dragon."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15.4"
  spec.add_development_dependency "rake", "~> 12.0.0"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency "appmodel", "~> 0.1.2"
  spec.add_development_dependency "selenium-webdriver", "~> 3.4.0"
  spec.add_development_dependency "logging", "~> 2.2"
  spec.add_development_dependency "sauce_whisk", "~> 0.1.0"
end
