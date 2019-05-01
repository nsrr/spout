# Spout

[![Build Status](https://travis-ci.com/nsrr/spout.svg?branch=master)](https://travis-ci.com/nsrr/spout)
[![Code Climate](https://codeclimate.com/github/nsrr/spout/badges/gpa.svg)](https://codeclimate.com/github/nsrr/spout)

Turn your CSV data dictionary into a JSON repository. Collaborate with others to
update the data dictionary in JSON format. Generate new Data Dictionary from the
JSON repository. Test and validate your data dictionary using built-in tests, or
add your own tests and validations.

Spout has been used extensively to curate and clean datasets available on the
[National Sleep Research Resource](https://sleepdata.org).

## Installation

Add this line to your application's `gems.rb`:

    gem "spout"

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

`id`: This column will give the variable its name, and also be used to name the
file, i.e. `<id>.json`

`folder`: This can be blank, however it is used to place variables into a folder
hiearchy. The folder column can contain forward slashes `/` to place a variable
into a subfolder. An example may be, `id`: `myvarid`,
`folder`: `Demographics/Subfolder` would create a file
`variables/Demographics/Subfolder/myvarid.json`

Other columns that will be interpreted include:

`display_name`: The variable name as it is presented to the user. The display
name should be fit on a single line.

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
  - `datetime`
  - `file`

`domain`: The name of the domain that is associated with the variable.
Typically, only variable of type `choices` have domains. These domains then
reside in `domains` folder.

`units`: A string of the associated that are appended to variable values, or
added to coordinates in graphs representing the variable.

`calculation`: A calculation represented using algebraic expressions along with
`id` of other variables.

`labels`: A series of different names for the variable that are semi-colon `;`
separated. These labels are commonly synonyms, or related terms used primarily
for searching.

All other columns get grouped into a hash labeled `other`.

#### Importing domains from an existing CSV file

```
spout import data_dictionary_domains.csv --domains
```

The CSV should contain at minimal three column headers:

`domain_id`: The name of the associated domain for the choice/option.

`value`: The value of the choice/option.

`display_name`: The display name of the choice/option.

Other columns that are imported include:

`description`: A longer description of the choice/option.

`folder`: The name of the folder path where the domain resides.


#### Importing forms from an existing CSV file

```
spout import data_dictionary_domains.csv --forms
```

The CSV should contain at minimal three column headers:

`folder`: This can be blank, however it is used to place forms into a folder
hiearchy. The folder column can contain forward slashes `/` to place a form
into a subfolder. An example may be, `id`: `family_history`,
`folder`: `Demographics/BaselineVisit` would create a file
`forms/Demographics/BaselineVisit/family_history.json`

`id`: The reference name of the form.

`display_name`: The name of the form.

Other columns that are imported include:

`code_book`: The file name of the document or PDF, including the file extension.


### Test your repository

If you created your data dictionary repository using `spout new`, you can go
ahead and test using:

```
spout test
```

If not, you can add the following to your `test` directory to include all Spout
tests, or just a subset of Spout tests.

`test/dictionary_test.rb`

```ruby
require "spout/tests"

class DictionaryTest < Minitest::Test
  # This line includes all default Spout Dictionary tests
  include Spout::Tests
end
```

```ruby
require "spout/tests"

class DictionaryTest < Minitest::Test
  # You can include only certain Spout tests by including them individually
  include Spout::Tests::JsonValidation
  include Spout::Tests::VariableTypeValidation
  include Spout::Tests::VariableNameUniqueness
  include Spout::Tests::DomainExistenceValidation
  include Spout::Tests::DomainFormat
  include Spout::Tests::DomainNameUniqueness
  include Spout::Tests::FormExistenceValidation
  include Spout::Tests::FormNameUniqueness
  include Spout::Tests::FormNameMatch
end
```

Then run either `spout test` or `bundle exec rake` to run your tests.

You can also use Spout iterators to create custom tests for variables, forms,
and domains in your data dictionary.

**Example Custom Test 1:** Test that `integer` and `numeric` variables have a
valid unit type

```ruby
class DictionaryTest < Minitest::Test
  # This line includes all default Spout Dictionary tests.
  include Spout::Tests

  # This line provides access to @variables, @forms, and @domains iterators
  # that can be used to write custom tests.
  include Spout::Helpers::Iterators

  VALID_UNITS = ["minutes", "hours"]

  @variables.select { |v| %w(numeric integer).include?(v.type) }.each do |variable|
    define_method("test_units: #{variable.path}") do
      message = "\"#{variable.units}\"".red + " invalid units.\n" +
                "             Valid types: " +
                VALID_UNITS.sort_by(&:to_s).collect { |u| u.inspect.white }.join(", ")
      assert VALID_UNITS.include?(variable.units), message
    end
  end
end
```

**Example Custom Test 2:** Tests that variables have at least 2 or more labels.

```ruby
class DictionaryTest < Minitest::Test
  # This line includes all default Spout Dictionary tests
  include Spout::Tests

  # This line provides access to @variables, @forms, and @domains
  # iterators that can be used to write custom tests
  include Spout::Helpers::Iterators

  @variables.select { |v| %w(numeric integer).include?(v.type) }.each do |variable|
    define_method("test_at_least_two_labels: #{variable.path}") do
      assert_operator 2, :<=, variable.labels.size
    end
  end
end
```


### Test your data dictionary coverage of your dataset

Spout lets you generate a nice visual coverage report that displays how well the
data dictionary covers your dataset. Place your dataset csvs into
`./csvs/<version>/` and then run the following Spout command:

```
spout coverage
```

This will generate an `index.html` file that can be opened and viewed in any
browser.

Spout coverage validates that values stored in your dataset match up with
variables and domains defined in your data dictionary.

### Identify outliers in your dataset

Spout lets you generate detect outliers in your underlying datasets. Place your
dataset csvs into `./csvs/<version>/` and then run the following Spout command:

```
spout outliers
```

This will generate an `outliers.html` file that can be opened and viewed in any
browser.

Spout outliers computes the
[inner and outer fences](http://www.wikihow.com/Calculate-Outliers) to identify
minor and major outliers in the dataset.

### Create a CSV Data Dictionary from your JSON repository

Provide an optional version parameter to name the folder the CSVs will be
generated in, defaults to what is in `VERSION` file, or if that does not
exist `1.0.0`.

```
spout export
```

You can optionally provide a version string

```
spout export [1.0.0]
```

### Generate charts and tables for data in your dataset

```
spout graphs
```

This command generates JSON charts and tables of each variable in a dataset

Requires a Spout YAML configuration file, `.spout.yml`, in the root of the data
dictionary that defines the variables used to create the charts:

- `visit`: This variable is used to separate subject encounters in a histogram
- `charts`: Array of choices, numeric, or integer variables for charts

Example `.spout.yml` file:

```yml
visit: visitnumber
charts:
- chart: age
  title: Age
- chart: gender
  title: Gender
- chart: race
  title: Race
```

To only generate graphs for a few select variables, add the variable names after
the `spout graphs` command.

For example, the command below will only generate graphs for the two variables
`ahi` and `bmi`.

```
spout g ahi bmi
```

You can also specify a limit to the amount of rows to read in from the CSV files
by specifying the `-rows` flag.

```
spout g --rows=10 ahi
```

This will generate a graph for ahi for the first 10 rows of each dataset CSV.


This will generate charts and tables for each variable in the dataset plotted
against the variables listed under `charts`.

### Example Variable that references a Domain and a Form

`variables/Demographics/gender.json`
```json
{
  "id": "gender",
  "display_name": "Gender",
  "description": "Gender as reported by subject",
  "type": "choices",
  "domain": "gender12",
  "labels": [
    "gender"
  ],
  "commonly_used": true,
  "forms": [
    "intake_questionnaire"
  ]
}
```

`domains/gender12.json`
```json
[
  {
    "value": "1",
    "display_name": "Male",
    "description": ""
  },
  {
    "value": "2",
    "display_name": "Female",
    "description": ""
  }
]
```

`forms/Baseline Visit/intake_questionnaire.json`
```json
{
  "id": "intake_questionnaire",
  "display_name": "Intake Questionnaire at Baseline Visit",
  "code_book": "Baseline-Visit-Intake-Questionnaire.pdf"
}
```

### Deploy your data dictionary to a staging or production webserver

```
spout deploy NAME
```

This command pushes a tagged version of the data dictionary to a webserver
specified in the `.spout.yml` file.

```
webservers:
  - name: production
    url: https://sleepdata.org
  - name: staging
    url: https://staging.sleepdata.org
```

Shorthand

**Deploy to Production**
```
spout d p
```

**Deploy to Staging**
```
spout d s
```

The following steps are run:

- **User Authorization**
  - User authenticates via token, the user must be a dataset editor
- **Version Check**
  - "v#{VERSION}" matches HEAD git tag annotation
  - `CHANGELOG.md` top line should include version, ex: `## 0.1.0`
  - Git Repo should have zero uncommitted changes
- **Tests Pass**
  - `spout t` passes for RC and FINAL versions
- **Dataset Coverage Check**
  - `spout c` passes for RC and FINAL versions
- **Graph Generation**
  - `spout g` is run
  - Graphs are pushed to server
- **Dataset Uploads**
  - Dataset CSV data dictionary is generated (variables, domains, forms)
  - Dataset and data dictionary CSVs uploaded to files section of dataset
- **Documentation Uploads**
  - `README.md` and `KNOWNISSUES.md` are uploaded
- **Server-Side Updates**
  - Server refreshes dataset folder to reflect new dataset and data dictionaries

### Check if you are using the latest version of Spout

You can check if a newer version of Spout is available by typing:

```
spout update
```
