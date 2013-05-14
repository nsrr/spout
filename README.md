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

bundle exec rake dd:import CSV=data_dictionary.csv
```

### Test your repository

```
spout test # or bundle exec rake
```

### Create a CSV Data Dictionary from your JSON repository

```
bundle exec rake dd:create
```
