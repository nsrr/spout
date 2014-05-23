require 'rake/testtask'
require 'colorize'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = true
  t.verbose = true
end

task default: :test

namespace :spout do
  require 'csv'
  require 'fileutils'
  require 'rubygems'
  require 'json'
  require 'erb'

  desc 'Create Data Dictionary from repository'
  task :create do
    folder = "dd/#{ENV['VERSION'] || standard_version}"
    puts "      create".colorize( :green ) + "  #{folder}"
    FileUtils.mkpath folder

    export_name = nil
    additional_keys = []

    if ENV['TYPE'] == 'hybrid'
      export_name = 'hybrid'
      additional_keys = [['hybrid', 'design_name'], ['hybrid', 'design_file'], ['hybrid', 'sensitivity'], ['hybrid', 'commonly_used']]
    end

    expanded_export(folder, export_name, additional_keys)
  end

  desc 'Initialize JSON repository from a CSV file: CSV=datadictionary.csv'
  task :import do
    puts ENV['CSV'].inspect
    if File.exists?(ENV['CSV'].to_s)
      ENV['TYPE'] == 'domains' ? import_domains : import_variables
    else
      puts "\nPlease specify a valid CSV file.".colorize( :red ) + additional_csv_info
    end
  end

  desc 'Match CSV dataset with JSON repository'
  task :coverage do
    require 'spout/tests/variable_type_validation'

    choice_variables = []

    Dir.glob("variables/**/*.json").each do |file|
      if json = JSON.parse(File.read(file)) rescue false
        choice_variables << json['id'] if json['type'] == 'choices'
      end
    end

    all_column_headers = []
    value_hash = {}
    csv_names = []

    Dir.glob("csvs/*.csv").each do |csv_file|
      csv_name = csv_file.split('/').last.to_s
      csv_names << csv_name
      puts "\nParsing: #{csv_name}"

      column_headers = []
      row_count = 0

      CSV.parse( File.open(csv_file, 'r:iso-8859-1:utf-8'){|f| f.read}, headers: true ) do |line|
        row = line.to_hash
        column_headers = row.collect{|key, val| [csv_name, key.to_s.downcase]} if row_count == 0

        print "." if row_count % 100 == 0

        choice_variables.each do |column_name|
          value_hash[column_name] ||= []
          value_hash[column_name] = value_hash[column_name] | [row[column_name]] if row[column_name]
        end

        row_count += 1
      end

      print "done\n"

      all_column_headers += column_headers
    end

    @matching_results = []

    all_column_headers.each do |csv, column|
      scr = SpoutCoverageResult.new(csv, column, value_hash[column])
      @matching_results << [ csv, column, scr ]
    end

    @matching_results.sort!{|a,b| [b[2].number_of_errors, a[0].to_s, a[1].to_s] <=> [a[2].number_of_errors, b[0].to_s, b[1].to_s]}

    @coverage_results = []

    csv_names.each do |csv_name|
      total_column_count = @matching_results.select{|mr| mr[0] == csv_name}.count
      mapped_column_count = @matching_results.select{|mr| mr[0] == csv_name and mr[2].number_of_errors == 0}.count
      @coverage_results << [ csv_name, total_column_count, mapped_column_count ]
    end

    coverage_folder = File.join(Dir.pwd, 'coverage')
    FileUtils.mkpath coverage_folder
    coverage_file = File.join(coverage_folder, 'index.html')

    print "\nGenerating: index.html\n\n"

    File.open(coverage_file, 'w+') do |file|
      erb_location = File.join( File.dirname(__FILE__), '../views/index.html.erb' )
      file.puts ERB.new(File.read(erb_location)).result(binding)
    end

    open_command = 'open'  if RUBY_PLATFORM.match(/darwin/) != nil
    open_command = 'start' if RUBY_PLATFORM.match(/mingw/) != nil

    system "#{open_command} #{coverage_file}" if ['start', 'open'].include?(open_command)
    puts "#{coverage_file}\n\n"
  end

  desc 'Match CSV dataset with JSON repository'
  task :images do
    require 'spout/commands/images'
    types         = ENV['types'].to_s.split(',').collect{|t| t.to_s.downcase}
    variable_ids  = ENV['variable_ids'].to_s.split(',').collect{|vid| vid.to_s.downcase}
    sizes         = ENV['sizes'].to_s.split(',').collect{|s| s.to_s.downcase}
    Spout::Commands::Images.new(types, variable_ids, sizes, standard_version)
  end

  desc 'Generate JSON charts and tables'
  task :json do
    require 'spout/commands/json_charts_and_tables'
    variables = ENV['variables'].to_s.split(',').collect{|s| s.to_s.downcase}
    Spout::Commands::JsonChartsAndTables.new(variables, standard_version)
  end

end

class SpoutCoverageResult
  attr_accessor :error, :error_message, :file_name_test, :json_id_test, :values_test, :valid_values, :csv_values, :variable_type_test, :json, :domain_test

  def initialize(csv, column, csv_values)
    load_json(column)
    load_valid_values

    @csv_values = csv_values
    @values_test = check_values
    @variable_type_test = check_variable_type
    @domain_test = check_domain_specified
  end

  def load_json(column)
    file = Dir.glob("variables/**/#{column}.json").first
    @file_name_test = (file != nil)
    @json = JSON.parse(File.read(file)) rescue @json = {}
    @json_id_test = (@json['id'].to_s.downcase == column)
  end

  def load_valid_values
    valid_values = []
    if @json['type'] == 'choices'
      file = Dir.glob("domains/**/#{@json['domain']}.json").first
      if json = JSON.parse(File.read(file)) rescue false
        valid_values = json.collect{|hash| hash['value']}
      end
    end
    @valid_values = valid_values
  end

  def number_of_errors
    @file_name_test && @json_id_test && @values_test && @variable_type_test && @domain_test ? 0 : 1
  end

  def check_values
    @json['type'] != 'choices' || (@valid_values | @csv_values.compact).size == @valid_values.size
  end

  def check_variable_type
    Spout::Tests::VariableTypeValidation::VALID_VARIABLE_TYPES.include?(@json['type'])
  end

  def check_domain_specified
    if @json['type'] != 'choices'
      true
    else
      domain_file = Dir.glob("domains/**/#{@json['domain']}.json").first
      if domain_json = JSON.parse(File.read(domain_file)) rescue false
        return domain_json.kind_of?(Array)
      end
      false
    end
  end

  def errored?
    error == true
  end
end

def number_with_delimiter(number, delimiter = ",")
  number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
end

def standard_version
  version = File.open('VERSION', &:readline).strip rescue ''
  version == '' ? '1.0.0' : version
end

def expanded_export(folder, export_name = nil, additional_keys = [])
  variables_export_file = "#{[export_name, 'variables'].compact.join('-')}.csv"
  puts "      export".colorize( :blue ) + "  #{folder}/#{variables_export_file}"
  CSV.open("#{folder}/#{variables_export_file}", "wb") do |csv|
    keys = %w(id display_name description type units domain labels calculation)
    csv << ['folder'] + keys + additional_keys.collect{|i| i[1]}
    Dir.glob("variables/**/*.json").each do |file|
      if json = JSON.parse(File.read(file)) rescue false
        variable_folder = variable_folder_path(file)
        csv << [variable_folder] + keys.collect{|key| json[key].kind_of?(Array) ? json[key].join(';') : json[key].to_s} + additional_keys.collect{|i| other_property(i[0], json, i[1])}
      end
    end
  end
  domains_export_file = "#{[export_name, 'domains'].compact.join('-')}.csv"
  puts "      export".colorize( :blue ) + "  #{folder}/#{domains_export_file}"
  CSV.open("#{folder}/#{domains_export_file}", "wb") do |csv|
    keys = %w(value display_name description)
    csv << ['folder', 'domain_id'] + keys
    Dir.glob("domains/**/*.json").each do |file|
      if json = JSON.parse(File.read(file)) rescue false
        domain_folder = domain_folder_path(file)
        domain_name = extract_domain_name(file)
        json.each do |hash|
          csv << [domain_folder, domain_name] + keys.collect{|key| hash[key]}
        end
      end
    end
  end
end

def extract_domain_name(file)
  file.gsub(/domains\//, '').split('/').last.to_s.gsub(/.json/, '')
end

def domain_folder_path(file)
  file.gsub(/domains\//, '').split('/')[0..-2].join('/')
end

def variable_folder_path(file)
  file.gsub(/variables\//, '').split('/')[0..-2].join('/')
end

def other_property(parent, json, property)
  json[parent] ? json[parent][property] : ''
end

def import_variables
  CSV.parse( File.open(ENV['CSV'].to_s, 'r:iso-8859-1:utf-8'){|f| f.read}, headers: true ) do |line|
    row = line.to_hash
    if not row.keys.include?('id')
      puts "\nMissing column header `".colorize( :red ) + "id".colorize( :light_cyan ) + "` in data dictionary.".colorize( :red ) + additional_csv_info
      exit(1)
    end
    next if row['id'] == ''
    folder = File.join('variables', row.delete('folder').to_s)
    FileUtils.mkpath folder
    hash = {}
    id = row.delete('id')
    hash['id'] = id
    hash['display_name'] = row.delete('display_name')
    hash['description'] = row.delete('description').to_s
    hash['type'] = row.delete('type')
    domain = row.delete('domain').to_s
    hash['domain'] = domain if domain != ''
    units = row.delete('units').to_s
    hash['units'] = units if units != ''
    calculation = row.delete('calculation').to_s
    hash['calculation'] = calculation if calculation != ''
    labels = row.delete('labels').to_s.split(';')
    hash['labels'] = labels if labels.size > 0
    hash['other'] = row unless row.empty?

    file_name = File.join(folder, id.to_s.downcase + '.json')
    File.open(file_name, 'w') do |file|
      file.write(JSON.pretty_generate(hash) + "\n")
    end
    puts "      create".colorize( :green ) + "  #{file_name}"
  end
end

def import_domains
  domains = {}

  CSV.parse( File.open(ENV['CSV'].to_s, 'r:iso-8859-1:utf-8'){|f| f.read}, headers: true ) do |line|
    row = line.to_hash
    if not row.keys.include?('domain_id')
      puts "\nMissing column header `".colorize( :red ) + "domain_id".colorize( :light_cyan ) + "` in data dictionary.".colorize( :red ) + additional_csv_info
      exit(1)
    end
    if not row.keys.include?('value')
      puts "\nMissing column header `".colorize( :red ) + "value".colorize( :light_cyan ) + "` in data dictionary.".colorize( :red ) + additional_csv_info
      exit(1)
    end
    if not row.keys.include?('display_name')
      puts "\nMissing column header `".colorize( :red ) + "display_name".colorize( :light_cyan ) + "` in data dictionary.".colorize( :red ) + additional_csv_info
      exit(1)
    end

    next if row['domain_id'].to_s == '' or row['value'].to_s == '' or row['display_name'].to_s == ''
    folder = File.join('domains', row['folder'].to_s).gsub(/[^a-zA-Z0-9_\/\.-]/, '_')
    domain_name = row['domain_id'].to_s.gsub(/[^a-zA-Z0-9_\/\.-]/, '_')
    domains[domain_name] ||= {}
    domains[domain_name]["folder"] = folder
    domains[domain_name]["options"] ||= []

    hash = {}
    hash['value'] = row.delete('value').to_s
    hash['display_name'] = row.delete('display_name').to_s
    hash['description'] = row.delete('description').to_s

    domains[domain_name]["options"] << hash
  end

  domains.each do |domain_name, domain_hash|
    folder = domain_hash["folder"]
    FileUtils.mkpath folder

    file_name = File.join(folder, domain_name.to_s.downcase + '.json')

    File.open(file_name, 'w') do |file|
      file.write(JSON.pretty_generate(domain_hash["options"]) + "\n")
    end
    puts "      create".colorize( :green ) + "  #{file_name}"
  end

end

def additional_csv_info
  "\n\nFor additional information on specifying CSV column headers before import see:\n\n    " + "https://github.com/sleepepi/spout#generate-a-new-repository-from-an-existing-csv-file".colorize( :light_cyan ) + "\n\n"
end
