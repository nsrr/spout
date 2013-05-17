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

The CSV should contain at minimal the two column headers:

`id`: This column will give the variable it's name, and also be used to name the file, i.e. `<id>.json`
`folder`: This can be blank, however it is used to place variables into a folder hiearchy. The folder column can contain forward slashes `/` to place a variable into a subfolder. An example may be, `id`: `myvarid`, `folder`: `Demographics/Subfolder` would create a file `variables/Demographics/Subfolder/myvarid.json`

Other columns that will be interpreted include:

`display_name`: The variable name as it is presented to the user. The display name should be reasonable in length and not unreasonably long.

`description`: A longer description of the variable.

`type`: Should be a valid variable type, i.e.:
  - `identifier`
  - `choices`
  - `integer`
  - `numeric`
  - `string`
  - `text`
  - `date`
  - `time`
  - `file`

`domain`: The name of the domain that is associated with the variable. Typically, only variable of type `choices` have domains.  These domains then reside in `domains` folder.

`units`: A string of the associated that are appended to variable values, or added to coordinates in graphs representing the variable.

`calculation`: A calculation represented using algebraic expressions along with `id` of other variables.

`labels`: A series of different names for the variable that are semi-colon `;` separated. These labels are commonly synonyms, or related terms used primarily for searching.

All other columns get grouped into a hash labeled `other`.

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

You can optionally provide a version string

```
spout export [1.0.0]
```

or

```
bundle exec rake dd:create [VERSION=1.0.0]
```
