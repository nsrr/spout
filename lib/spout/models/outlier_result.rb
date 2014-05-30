require 'spout/helpers/array_statistics'
require 'spout/helpers/json_loader'

module Spout
  module Models
    class OutlierResult
      attr_reader :csv_files, :method, :major_outliers, :minor_outliers, :outliers, :weight, :units, :median

      def initialize(subjects, method, csv_files)
        @values = subjects.collect(&method.to_sym)
        @csv_files = csv_files
        @method = method


        calculate_outliers!

        @weight = if @major_outliers.count > 0
          0
        elsif @minor_outliers.count > 0
          1
        else
          2
        end
        variable = Spout::Helpers::JsonLoader::get_variable(method)
        @units = (variable.kind_of?(Hash) ? variable['units'] : nil)
        @median = @values.median
      end

      def calculate_outliers!
        @major_outliers = @values.major_outliers.uniq
        @minor_outliers = @values.minor_outliers.uniq
        @outliers = @values.outliers.uniq
      end

    end

  end
end
