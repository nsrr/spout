require 'rake/testtask'

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

    CSV.open("#{folder}/variables.csv", "wb") do |csv|
      keys = %w(id display_name description type domain)
      csv << ['folder'] + keys
      Dir.glob("variables/**/*.json").each do |file|
        if json = JSON.parse(File.read(file)) rescue false
          variable_folder = file.gsub(/variables\//, '').split('/')[0..-2].join('/')
          csv << [variable_folder] + keys.collect{|key| json[key]}
        end
      end
    end
    CSV.open("#{folder}/domains.csv", "wb") do |csv|
      keys = %w(value display_name description)
      csv << ['id'] + keys
      Dir.glob("domains/**/*.json").each do |file|
        if json = JSON.parse(File.read(file)) rescue false
          domain_name = file.gsub(/domains\//, '')
          json.each do |hash|
            csv << [domain_name] + keys.collect{|key| hash[key]}
          end
        end
      end
    end

    puts "Data Dictionary Created in #{folder}"
  end

  desc 'Initialize JSON repository from a CSV file: CSV=datadictionary.csv'
  task :import do
    puts ENV['CSV'].inspect
    if File.exists?(ENV['CSV'].to_s)
      CSV.parse( File.open(ENV['CSV'].to_s, 'r:iso-8859-1:utf-8'){|f| f.read}, headers: true ) do |line|
        row = line.to_hash
        next if row['COLUMN'] == ''
        folder = File.join('variables', row['FOLDER'])
        FileUtils.mkpath folder
        hash = {}
        hash['id'] = row['COLUMN']
        hash['display_name'] = row['DISPLAY_NAME']
        hash['description'] = row['DESCRIPTION'].to_s
        hash['type'] = row['VARIABLE_TYPE']
        hash['domain'] = row['DOMAIN'] if row['DOMAIN'] != '' and row['DOMAIN'] != nil
        hash['units'] = row['UNITS'] if row['UNITS'] != '' and row['UNITS'] != nil
        hash['calculation'] = row['CALCULATION'] if row['DOMAIN'] != '' and row['CALCULATION'] != nil
        hash['labels'] = row['LABELS'].to_s.split(';') if row['LABELS'].to_s.split(';').size > 0

        File.open(File.join(folder, row['COLUMN'].downcase + '.json'), 'w') do |file|
          file.write(JSON.pretty_generate(hash))
        end
      end
      puts "Data Dictionary Imported from CSV."
    else
      puts "Please specify a valid CSV file."
    end
  end
end
