# frozen_string_literal: true

# Compiling the Gem
# gem build spout.gemspec
# gem install ./spout-x.x.x.gem --no-document --local
#
# gem push spout-x.x.x.gem
# gem list -r spout
# gem install spout

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spout/version'

Gem::Specification.new do |spec|
  spec.name          = 'spout'
  spec.version       = Spout::VERSION::STRING
  spec.authors       = ['Remo Mueller']
  spec.email         = ['remosm@gmail.com']
  spec.description   = 'Manage your data dictionary as a JSON repository, and easily export back to CSV.'
  spec.summary       = 'Turn your CSV data dictionary into a JSON repository. '\
                       'Collaborate with others to update the data dictionary '\
                       'in JSON format. Generate new Data Dictionary from the '\
                       'JSON repository. Test and validate your data '\
                       'dictionary using built-in tests, or add your own for '\
                       'further validations.'
  spec.homepage      = 'https://github.com/sleepepi/spout'
  spec.license       = 'MIT'

  spec.files = Dir['{bin,lib}/**/*'] + ['CHANGELOG.md', 'LICENSE', 'Rakefile', 'README.md', 'spout.gemspec']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'bundler', '~> 1.13'
  spec.add_dependency 'rake'
  spec.add_dependency 'minitest'
  spec.add_dependency 'minitest-reporters'
  spec.add_dependency 'json'
  spec.add_dependency 'colorize', '~> 0.8.1'
end
