require "spout/version"
require "spout/application"
require 'spout/tasks'

Spout::COMMANDS = {
  'n' => :new_project,
  'v' => :version,
  't' => :test,
  'i' => :importer,
  'e' => :exporter,
  'c' => :coverage_report,
  'p' => :generate_images,
  'g' => :generate_charts_and_tables,
  'o' => :outliers_report
}

module Spout
  def self.launch(argv)
    self.send((Spout::COMMANDS[argv.first.to_s.scan(/\w/).first] || :help), argv)
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
    variables = argv.collect{|s| s.to_s.downcase}
    Spout::Commands::Graphs.new(variables, standard_version)
  end

  def self.generate_images(argv)
    argv = argv.last(argv.size - 1)
    require 'spout/commands/images'
    types         = flag_values(argv, 'type')
    variable_ids  = flag_values(argv, 'id')
    sizes         = flag_values(argv, 'size')
    Spout::Commands::Images.new(types, variable_ids, sizes, standard_version, argv)
  end

  def self.help(argv)
    puts <<-EOT

Usage: spout COMMAND [ARGS]

The most common spout commands are:
  [n]ew             Create a new Spout dictionary.
                    `spout new <project_name>` creates a new
                    data dictionary in `./<project_name>`
  [t]est            Run tests and show failing tests
  [t] --verbose     Run the tests and show passing and failing
                    tests
  [i]mport          Import a CSV file into the JSON dictionary
  [e]xport [1.0.0]  Export the JSON dictionary to CSV format
  [c]overage        Coverage report, requires dataset CSVs
                    in `<project_name>/csvs/<version>`
  [o]utliers        Outlier report, requires dataset CSVs
                    in `<project_name>/csvs/<version>`
  [p]ngs            Generates images for each variable in a
                    dataset and places them
                    in `<project_name>/images/<version>/`
  [g]raphs          Generates JSON graphs for each variable
                    in a dataset and places them
                    in `<project_name>/graphs/<version>/`
  [v]ersion         Returns the version of Spout

Commands can be referenced by the first letter:
  Ex: `spout t`, for test

EOT
  end

  def self.importer(argv)
    require 'spout/commands/importer'
    Spout::Commands::Importer.new(argv)
  end

  def self.outliers_report(argv)
    require 'spout/commands/outliers'
    Spout::Commands::Outliers.new(standard_version, argv)
  end

  def self.test(argv)
    hide_passing_tests = (argv.delete('--verbose') == nil)
    system "bundle exec rake#{' HIDE_PASSING_TESTS=true' if hide_passing_tests}"
    # require 'spout/commands/test_runner'
    # Spout::Commands::TestRunner.new(argv)
  end

  def self.version(argv)
    puts "Spout #{Spout::VERSION::STRING}"
  end

  def self.standard_version
    version = File.open('VERSION', &:readline).strip rescue ''
    version == '' ? '1.0.0' : version
  end

  private

  def self.flag_values(flags, param)
    flags.select{|f| f[0..((param.size + 3) - 1)] == "--#{param}-" and f.length > param.size + 3}.collect{|f| f[(param.size + 3)..-1]}
  end

end
