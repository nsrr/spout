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

  desc 'Create Data Dictionary from repository'
  task :create do

    folder = "dd/#{ENV['VERSION'] || Spout::Application.new.version}"
    FileUtils.mkpath folder

    case ENV['TYPE']
    when 'hybrid'
      hybrid_export(folder)
    else
      standard_export(folder)
    end


    puts "Data Dictionary Created in #{folder}"
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
end

def standard_export(folder)
  CSV.open("#{folder}/variables.csv", "wb") do |csv|
    keys = %w(id display_name description type units domain labels calculation)
    csv << ['folder'] + keys
    Dir.glob("variables/**/*.json").each do |file|
      if json = JSON.parse(File.read(file)) rescue false
        variable_folder = variable_folder_path(file)
        csv << [variable_folder] + keys.collect{|key| json[key].kind_of?(Array) ? json[key].join(';') : json[key].to_s}
      end
    end
  end
  CSV.open("#{folder}/domains.csv", "wb") do |csv|
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

def hybrid_concept_type(json)
  if json['hybrid'] and json['hybrid']['type'].to_s != ''
    json['hybrid']['type']
  else
    hybrid_concept_type_map(json['type'])
  end
end

def hybrid_concept_type_map(variable_type)
  hybrid_types = { "choices" => "categorical",
                   "numeric" => "continuous",
                   "integer" => "continuous",
                   "string" => "free text",
                   "text" => "free text",
                   "date" => "datetime",
                   "time" => "datetime",
                   "file" => "free text" }
  hybrid_types[variable_type] || variable_type
end

def hybrid_property(json, property)
  json['hybrid'] ? json['hybrid'][property] : ''
end

def hybrid_export(folder)
  domain_parents = {}
  CSV.open("#{folder}/hybrid.csv", "wb") do |csv|
    csv << ["#URI", "Namespace", "Short Name", "Description", "Concept Type", "Units", "Terms", "Internal Terms", "Parents", "Children", "Field Values", "Sensitivity", "Display Name", "Commonly Used", "Folder", "Calculation", "Source Name", "Source File"]
    Dir.glob("variables/**/*.json").each do |file|
      if json = JSON.parse(File.read(file)) rescue false
        if json['domain'].to_s != ''
          domain_parents[json['domain'].to_s.downcase] ||= []
          domain_parents[json['domain'].to_s.downcase] << "#"+json['id'].to_s
        end
        row = [
          '',                         # URI
          '',                         # Namespace
          json['id'],                 # Short Name
          json['description'],        # Description
          hybrid_concept_type(json),  # Concept Type
          json['units'],              # Units
          '',                         # Terms
          '',                         # Internal Terms
          '',                         # Parents
          '',                         # Children
          '',                         # Field Values
          hybrid_property(json, 'access level'),   # Sensitivity
          json['display_name'],       # Display Name
          hybrid_property(json, 'Commonly Used'), # Commonly Used
          variable_folder_path(file).gsub('/', ':'), # Folder
          json['calculation'],                         # Calculation
          hybrid_property(json, 'SOURCE'), # Source Name
          hybrid_property(json, 'filename') # Source File
        ]
        csv << row
      end
    end
    Dir.glob("domains/**/*.json").each do |file|
      if json = JSON.parse(File.read(file)) rescue false
        json.each do |option|
          row = [
            '',                         # URI
            '',                         # Namespace
            extract_domain_name(file)+'_'+option['value'].to_s,  # Short Name
            option['description'],      # Description
            'boolean',  # Concept Type
            '',              # Units
            '',                         # Terms
            option['value'],            # Internal Terms
            (domain_parents[extract_domain_name(file).downcase] || []).join(';'),                         # Parents
            '',                         # Children
            '',                         # Field Values
            '0',                        # Sensitivity
            option['display_name'],     # Display Name
            '', # Commonly Used
            domain_folder_path(file).gsub('/', ':'), # Folder
            '',                         # Calculation
          ]
          csv << row
        end
      end
    end
  end
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
