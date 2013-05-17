# Compiling the Gem
# gem build spout.gemspec
# gem install ./spout-x.x.x.gem --no-ri --no-rdoc --local
#
# gem push spout-x.x.x.gem
# gem list -r spout
# gem install spout

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spout/version'

Gem::Specification.new do |spec|
  spec.name          = "spout"
  spec.version       = Spout::VERSION::STRING
  spec.authors       = ["Remo Mueller"]
  spec.email         = ["remosm@gmail.com"]
  spec.description   = %q{Manage your data dictionary as a JSON repository, and easily export back to CSV.}
  spec.summary       = %q{Turn your CSV data dictionary into a JSON repository. Collaborate with others to update the data dictionary in JSON format. Generate new Data Dictionary from the JSON repository. Test and validate your data dictionary using built-in tests, or add your own for further validations.}
  spec.homepage      = "https://github.com/sleepepi"
  spec.license       = "CC BY-NC-SA 3.0"

  spec.files = Dir['{bin,lib}/**/*'] + ['CHANGELOG.md', 'LICENSE', 'Rakefile', 'README.md', 'spout.gemspec']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rake"
  spec.add_dependency "turn"
  spec.add_dependency "json"
  spec.add_dependency "colorize", "~> 0.5.8"

  spec.add_development_dependency "bundler", "~> 1.3"
end
