## 0.2.0

### Enhancements
- Domains can now be imported using `spout import_domains CSVFILE`

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
