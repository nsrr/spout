require 'rake/testtask'
require 'colorize'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = true
  t.verbose = true
end

task :default => :test

namespace :dd do
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
    puts 'MDR'
    puts Dir.pwd
    puts csvs = Dir.glob("dd/csvs/*.csv")

    @all_column_headers = []

    @variable_json_ids = []
    @variable_file_names = []

    Dir.glob("variables/**/*.json").each do |file|
      if json = JSON.parse(File.read(file)) rescue false
        @variable_json_ids << json['id']
      end
      @variable_file_names << file.split('/').last.to_s.split('.json').first.to_s
    end

    csvs.each do |csv_file|
      column_headers = []

      CSV.parse( File.open(csv_file, 'r:iso-8859-1:utf-8'){|f| f.read} ) do |line|
        column_headers = line
        break # Only read first line
      end

      column_headers.each do |column_header|

      end

      @all_column_headers += column_headers
    end


    @all_column_headers

    # puts File.join(File.dirname(__FILE__), '../views/', "")

    coverage_file = File.join(Dir.pwd, 'dd', 'index.html')

    File.open(coverage_file, 'w+') do |file|
      name = 'index.html'
      erb_location = File.join(File.dirname(__FILE__), '../views/', "#{name}.erb")
      file.puts ERB.new(File.read(erb_location)).result(binding)
    end

    open_command = 'open'  if RUBY_PLATFORM.match(/darwin/) != nil
    open_command = 'start' if RUBY_PLATFORM.match(/mingw/) != nil


    system "#{open_command} #{coverage_file}" if ['start', 'open'].include?(open_command)
    puts coverage_file
  end

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

    file_name = File.join(folder, id.downcase + '.json')
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

    file_name = File.join(folder, domain_name.downcase + '.json')

    File.open(file_name, 'w') do |file|
      file.write(JSON.pretty_generate(domain_hash["options"]) + "\n")
    end
    puts "      create".colorize( :green ) + "  #{file_name}"
  end

end

def additional_csv_info
  "\n\nFor additional information on specifying CSV column headers before import see:\n\n    " + "https://github.com/sleepepi/spout#generate-a-new-repository-from-an-existing-csv-file".colorize( :light_cyan ) + "\n\n"
end
