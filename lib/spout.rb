# frozen_string_literal: true

require 'spout/version'

require 'spout/models/dictionary'

Spout::COMMANDS = {
  'c' => :coverage_report,
  'd' => :deploy,
  'e' => :exporter,
  'g' => :generate_charts_and_tables,
  'i' => :importer,
  'n' => :new_project,
  'o' => :outliers_report,
  't' => :test,
  'u' => :update,
  'v' => :version
}

# Launch spout commands from command line.
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
  rescue NoMemoryError
    puts "[NoMemoryError] You made Spout cry... Spout doesn't run on potatoes :'-("
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

  def self.help(argv)
    require 'spout/commands/help'
    Spout::Commands::Help.new(argv)
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

  def self.update(argv)
    require 'spout/commands/update'
    Spout::Commands::Update.start(argv)
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
