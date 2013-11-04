# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'subcommand_optparse/version'

Gem::Specification.new do |spec|
  spec.name          = "subcommand-optparse"
  spec.version       = SubCmdOptParser::VERSION
  spec.authors       = ["Takayuki YAMAGUCHI"]
  spec.email         = ["d@ytak.info"]
  spec.description   = "Option parser for subcommands"
  spec.summary       = "Option parser for a command with subcommands, which is parsed by library 'optparse'"
  spec.homepage      = ""
  spec.license       = "GPLv3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
