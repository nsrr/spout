## 0.3.0

### Enhancements
- Tests now hide passing tests by default
  - To show all tests, use `spout tv`, or `bundle exec rake`
- Tests now include check for variable and domain name uniqueness across folders
  - `include Spout::Tests::VariableNameUniqueness`
  - `include Spout::Tests::DomainNameUniqueness`
- Exports will now create a folder based on the version specified in the `VERSION` file located in the root of the data dictionary
  - If a version is specified, `spout export 1.0.1` then the command line version is used
  - If no version is specified, and no `VERSION` file exists, then the default `1.0.0` is used
  - The version must be specified on the first line in the `VERSION` file
- Use of Ruby 2.0.0-p247 is now recommended

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
