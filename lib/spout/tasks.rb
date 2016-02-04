# frozen_string_literal: true

# Load Spout rakefile extensions
%w(
  engine
).each do |task|
  # puts "Loading file: #{task}.rake"
  load "spout/tasks/#{task}.rake"
end
