# module Spout
#   class Actions

#     def interpret(argv)
#       # case argv.first.to_s.scan(/\w/).first
#       case argv.first
#       when 'new', 'n', 'ne', '-new', '-n', '-ne'
#         new_template_dictionary(argv)
#       when '--version', '-v', '-ve', '-ver', 'version', 'v', 've', 'ver'
#         puts "Spout #{Spout::VERSION::STRING}"
#       when 'test', 't', 'te', 'tes', '--test', '-t', '-te', '-tes'
#         system "bundle exec rake HIDE_PASSING_TESTS=true"
#       # when 'tv'
#       #   system "bundle exec rake"
#       when 'import', 'i', 'im', 'imp', '--import', '-i', '-im', '-imp'
#         import_from_csv(argv)
#       when 'import_domain', '--import_domain', 'import_domains', '--import_domains'
#         import_from_csv(argv, 'domains')
#       when 'export', 'e', 'ex', 'exp', '--export', '-e', '-ex', '-exp'
#         new_data_dictionary_export(argv)
#       when 'coverage', '-coverage', '--coverage', 'c', '-c'
#         coverage_report(argv)
#       when 'pngs', '-pngs', '--pngs', 'p', '-p'
#         generate_images(argv.last(argv.size - 1))
#       when 'graphs', '-graphs', '--graphs', 'g', '-g'
#         generate_charts_and_tables(argv.last(argv.size - 1))
#       when 'outliers', '-outliers', '--outliers', 'o', '-o'
#         outliers_report(argv)
#       # else
#       #   help
#       end
#     end

#     protected

#       def csv_usage
#         usage = <<-EOT

# Usage: spout import CSVFILE

# The CSVFILE must be the location of a valid CSV file.

# EOT
#         usage
#       end

#       def import_from_csv(argv, type = "")
#         csv_file = File.join(argv[1].to_s.strip)
#         if File.exists?(csv_file)
#           system "bundle exec rake spout:import CSV=#{csv_file} #{'TYPE='+type if type.to_s != ''}"
#         else
#           puts csv_usage
#         end
#       end

#       def new_data_dictionary_export(argv)
#         version = argv[1].to_s.gsub(/[^a-zA-Z0-9\.-]/, '_').strip
#         version_string = (version == '' ? "" : "VERSION=#{version}")
#         system "bundle exec rake spout:create #{version_string}"
#       end

#       def coverage_report(argv)
#         require 'spout/commands/coverage'
#         Spout::Commands::Coverage.new(standard_version, argv)
#         # system "bundle exec rake spout:coverage"
#       end

#       def outliers_report(argv)
#         system "bundle exec rake spout:outliers"
#       end

#       def flag_values(flags, param)
#         flags.select{|f| f[0..((param.size + 3) - 1)] == "--#{param}-" and f.length > param.size + 3}.collect{|f| f[(param.size + 3)..-1]}
#       end

#       def generate_images(flags)
#         params = {}
#         params['types']        = flag_values(flags, 'type')
#         params['variable_ids'] = flag_values(flags, 'id')
#         params['sizes']        = flag_values(flags, 'size')

#         params_string = params.collect{|key, values| "#{key}=#{values.join(',')}"}.join(' ')

#         system "bundle exec rake spout:images #{params_string}"
#       end

#       def generate_charts_and_tables(variables)
#         system "bundle exec rake spout:json variables=#{variables.join(',')}"
#       end

#   end
# end
