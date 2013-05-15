# Spout

Turn your CSV data dictionary into a JSON repository. Collaborate with others to update the data dictionary in JSON format. Generate new Data Dictionary from the JSON repository. Test and validate your data dictionary using built-in tests, or add your own for further validations.

## Installation

Add this line to your application's Gemfile:

    gem 'spout'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spout

## Usage

### Generate a new repository from an existing CSV file

```
spout new my_data_dictionary

cd my_data_dictionary

spout import data_dictionary.csv
```

### Test your repository

If you created your data dictionary repository using `spout new`, you can go ahead and test using:

```
spout test
```

If not, you can add the following to your `test` directory to include all Spout tests, or just a subset of Spout tests.

`test/dictionary_test.rb`

```
require 'spout/tests'

class DictionaryTest < Test::Unit::TestCase
  include Spout::Tests
end
```

```
require 'spout/tests'

class DictionaryTest < Test::Unit::TestCase
  # Or only include certain tests
  include Spout::Tests::JsonValidation
  include Spout::Tests::VariableTypeValidation
end
```

Then run either `spout test` or `bundle exec rake` to run your tests.


### Create a CSV Data Dictionary from your JSON repository

Provide an optional version parameter to name the folder the CSVs will be generated in, defaults to 1.0.0 currently.

```
spout export
```

or

```
bundle exec rake dd:create [VERSION=1.0.0]
```
