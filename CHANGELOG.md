## 0.9.0

### Enhancements
- **General Changes**
  - `spout c`, `spout o`, `spout g`, `spout p`, will now use datasets that are compatible with the data dictionary
    - The following examples use a Data Dictionary that is currently on version 0.2.1.beta2
    - Ex: If a dataset exists in folder 0.2.0, then this folder will be used.
    - Ex: If datasets exist in 0.2.0, 0.2.1.beta2, and 0.2.1, then the exact match, 0.2.1.beta2, will be used.
    - Ex: If datasets exist in 0.2.0, 0.2.1.beta1, 0.2.1, and 0.3.0, then the highest match on the minor version is used, in this case 0.2.1.
  - `spout p` command now uses same syntax as `spout g` command to reference variables
    - `spout p <variable_id>`
    - `spout p age --size-sm`
  - The data dictionary slug can now be specified in the `spout.yml` file:
    - `slug: my-repo-name`
    - Setting the slug will allow the `spout export` command to export the data dictionary to `my-repo-name-data-dictionary-0.1.0-variables.csv`, etc.
  - `spout p` and `spout g` now indicate if the target CSV folder is empty
  - `spout o` now only calculates averages and outliers for `numeric` and `integer` variables
- **Gem Changes**
  - Use of Ruby 2.1.3 is now recommended

## 0.8.0 (June 27, 2014)

### Enhancements
- **Testing Changes**
  - Tests now include check for variables that reference one or more forms
    - `include Spout::Tests::FormExistenceValidation`
    - `include Spout::Tests::FormNameUniqueness`
    - `include Spout::Tests::FormNameMatch`
  - Test iterators have been added to provide access to `@variables`, `@forms`, and `@domains` to build custom tests in `dictionary_test.rb`
    - Add the line `include Spout::Helpers::Iterators` to `dictionary_test.rb` to access the iterators
    - See [README.md](https://github.com/sleepepi/spout/blob/master/README.md) for examples
  - Spout tests are now run using `Minitest` in favor of `Test::Unit`
- **Graph Generation Changes**
  - Added `spout graphs` command that generates JSON charts and tables of each variable in a dataset
    - This command requires a `.spout.yml` file to be specified to identify the following variables:
      - `visit`: This variable is used to separate subject encounters in a histogram
      - `charts`: Array of choices, numeric, or integer variables for charts
  - Graphs for histograms now specify units on the x-axis
  - The `spout graphs` command does not generate graphs when no underlying values exists for the variable
- **Image Generation Changes**
  - The `spout pngs` command now renders the histogram for each variable
- **Coverage Command Changes**
  - The `spout coverage` command now lists variables that are defined in the data dictionary and that do not exist in any CSV dataset
  - The `spout coverage` command now lists domains that are defined in the data dictionary and not referenced by any variable
- **Outlier Identification Changes**
  - Added `spout outliers` command that returns a list of integer or numeric variables that contain major and minor outliers
- **Export Command Changes**
  - The `spout export` command now includes a `forms.csv` file that exports form information referenced by variables
- **General Changes**
  - Spout dictionary can now be loaded using the following command in `irb`:
  ```ruby
  require 'spout'
  dictionary = Spout::Models::Dictionary.new(Dir.pwd)
  dictionary.load_all!
  dictionary.variables.count
  dictionary.domains.count
  dictionary.forms.count
  ```
  - Removed the deprecated `spout hybrid` command
- **Gem Changes**
  - Use of Ruby 2.1.2 is now recommended
  - Updated to colorize 0.7.2
  - Updated to minitest

### Bug Fix
- Spout commands are now more consistently case insensitive for file and column names across platforms
- The `spout import` command now correctly makes variable ids and domain ids consistently lowercase

### Testing
- Refactored Spout code and updated test coverage for all major spout commands

## 0.7.0 (April 16, 2014)

### Enhancements
- Added `spout pngs` command that generates pie charts and histograms of each variable in a dataset
  - The following flags are available:
    - `spout p --type-numeric`
    - `spout p --type-integer`
    - `spout p --type-choices`
    - `spout p --size-lg`
    - `spout p --size-sm`
    - `spout p --type-numeric --size-sm`
  - For specific variables the following can be used:
    - `spout p --id-<variable_id>` **NOTE** changed in v0.9.0

## 0.6.0 (March 7, 2014)

### Enhancement
- Added `spout coverage` command that generates a coverage report of how well a dataset matches the data dictionary
  - Generates a viewable report in `<project_name>/coverage/index.html` that shows which columns are covered in CSVs located in `<project_name>/csvs/`
  - Checks that all collected values for a variable with a domain exist in the associated domain
- **Gem Changes**
  - Updated to colorize 0.6.0

## 0.5.0 (February 28, 2014)

### Enhancement
- Tests added to check that variables of type choices have specified a domain
- Tests added to make sure the JSON object `id` matches the variable file name
- Use of Ruby 2.1.1 is now recommended

## 0.4.1 (August 16, 2013)

### Enhancement
- The `spout new <project_name>` command now adds .keep files to the variables and domains folders so they don't need to be recreated in a cloned empty repository

## 0.4.0 (August 7, 2013)

### Enhancements
- Tests for domain existence have changed and now only require the domain name be referenced from the variable instead of the entire domain path
  - To reference a domain from a variable, only the domain name is now required.
  - This change decouples the relative domain folder location from needing to be added among multiple variables which now allows domains to be reorganized without requiring the corresponding variables to be updated to reflect the new path
  - This change is possible since domains need to have a unique name regardless of where they are located

## 0.3.0 (July 11, 2013)

### Enhancements
- Tests now hide passing tests by default
  - To show all tests, use `spout tv`, or `bundle exec rake`
- Tests now include check for variable and domain name uniqueness across folders
  - `include Spout::Tests::VariableNameUniqueness`
  - `include Spout::Tests::DomainNameUniqueness`
- Tests now allow `datetime` as a valid variable type
- Exports will now create a folder based on the version specified in the `VERSION` file located in the root of the data dictionary
  - If a version is specified, `spout export 1.0.1` then the command line version is used
  - If no version is specified, and no `VERSION` file exists, then the default `1.0.0` is used
  - The version must be specified on the first line in the `VERSION` file
- Spout can now create a new Spout project in a folder that was cloned from a Git repository
- Use of Ruby 2.0.0-p247 is now recommended

### Bug Fix
- `DomainExistenceValidation` tests are now case-insensitive

## 0.2.0 (June 26, 2013)

### Enhancements
- Domains can now be imported using `spout import_domains CSVFILE`
- Data Dictionary can now be exported to the Hybrid data dictionary CSV format along with an optional version number:
  - `spout hybrid [1.0.0]`

## 0.1.0 (May 21, 2013)

### Enhancements
- Existing Data Dictionaries can be converted to JSON format from a CSV file
  - Recognized columns:
    - `folder`
    - `id`
    - `display_name`
    - `description`
    - `type`
    - `domain`
    - `units`
    - `calculation`
    - `labels`
  - All other columns will go into an `Other` JSON hash
- Added a rake task to create CSVs of the JSON data dictionary
- Added tests for JSON validity of variables and domains
- Added test to check presence/validity of variable type
- Added test to check if a domain referenced from a variable exists
- Tests can now be added as a group, or on a test-by-test basis
  - Add `require 'spout/tests'` to your individual tests, or to your `test_helper.rb`
  - Include the all or some of the tests provided by Spout
    - `include Spout::Tests` for all tests
    - `include Spout::Tests::JsonValidation` to verify valid JSON formats of domains and variables
    - `include Spout::Tests::VariableTypeValidation` to verify valid variable type for variables
    - `include Spout::Tests::DomainExistenceValidation` to verify existence of domains referenced by variables
- Added `spout new FOLDER` to create an empty data dictionary in the specified `FOLDER`
