require 'spout/version'

require 'spout/models/dictionary'

Spout::COMMANDS = {
  'n' => :new_project,
  'v' => :version,
  't' => :test,
  'i' => :importer,
  'e' => :exporter,
  'c' => :coverage_report,
  'g' => :generate_charts_and_tables,
  'o' => :outliers_report,
  'd' => :deploy
}

module Spout
  def self.launch(argv)
    send((Spout::COMMANDS[argv.first.to_s.scan(/\w/).first] || :help), argv)
  end

  def self.new_project(argv)
    require 'spout/commands/project_generator'
    Spout::Commands::ProjectGenerator.new(argv)
  end

  def self.coverage_report(argv)
    require 'spout/commands/coverage'
    Spout::Commands::Coverage.new(standard_version, argv)
  end

  def self.exporter(argv)
    require 'spout/commands/exporter'
    Spout::Commands::Exporter.new(standard_version, argv)
  end

  def self.generate_charts_and_tables(argv)
    argv = argv.last(argv.size - 1)
    require 'spout/commands/graphs'
    Spout::Commands::Graphs.new(argv, standard_version)
  end

  def self.help(_argv)
    puts <<-EOT

Usage: spout COMMAND [ARGS]

The most common spout commands are:
  [n]ew             Create a new Spout dictionary.
                    `spout new <project_name>` creates a new
                    data dictionary in `./<project_name>`
  [t]est            Run tests and show failing tests
  [i]mport          Import a CSV file into the JSON dictionary
  [e]xport [1.0.0]  Export the JSON dictionary to CSV format
  [c]overage        Coverage report, requires dataset CSVs
                    in `<project_name>/csvs/<version>`
  [o]utliers        Outlier report, requires dataset CSVs
                    in `<project_name>/csvs/<version>`
  [g]raphs          Generates JSON graphs for each variable
                    in a dataset and places them
                    in `<project_name>/graphs/<version>/`
  [d]eploy NAME     Push dataset and data dictionary to a
                    webserver specified in `.spout.yml`
  [v]ersion         Returns the version of Spout

Commands can be referenced by the first letter:
  Ex: `spout t`, for test

EOT
  end

  def self.deploy(argv)
    require 'spout/commands/deploy'
    Spout::Commands::Deploy.new(argv, standard_version)
  end

  def self.importer(argv)
    require 'spout/commands/importer'
    Spout::Commands::Importer.new(argv)
  end

  def self.outliers_report(argv)
    require 'spout/commands/outliers'
    Spout::Commands::Outliers.new(standard_version, argv)
  end

  def self.test(_argv)
    system 'bundle exec rake'
    # require 'spout/commands/test_runner'
    # Spout::Commands::TestRunner.new(argv)
  end

  def self.version(_argv)
    puts "Spout #{Spout::VERSION::STRING}"
  end

  def self.standard_version
    version = File.open('VERSION', &:readline).strip
    version == '' ? '1.0.0' : version
  rescue
    '1.0.0'
  end
end
