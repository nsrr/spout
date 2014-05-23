require 'spout/helpers/table_formatting'

module Spout
  module Helpers
    class ChartTypes
      def self.get_bucket(buckets, value)
        buckets.each do |b|
          return "#{b[0].round(1)} to #{b[1].round(1)}" if value >= b[0] and value <= b[1]
        end
        nil
      end

      def self.continuous_buckets(values)
        return [] if values.count == 0
        minimum_bucket = values.min
        maximum_bucket = values.max

        max_buckets = [(maximum_bucket - minimum_bucket), 12].min
        bucket_size = (maximum_bucket - minimum_bucket) / max_buckets
        buckets = []
        (0..(max_buckets-1)).to_a.each do |index|
          start = minimum_bucket + index * bucket_size
          stop = start + bucket_size
          buckets << [start,stop]
        end
        buckets
      end

      def self.get_json(file_name, file_type)
        file = Dir.glob("#{file_type}s/**/#{file_name}.json").first
        json = JSON.parse(File.read(file)) rescue json = nil
        json
      end

      def self.get_variable(variable_name)
        get_json(variable_name, 'variable')
      end

      def self.get_domain(json)
        get_json(json['domain'], 'domain')
      end


      def self.chart_arbitrary_choices_by_quartile(chart_type, subjects, json, method)
        # CHART TYPE IS THE QUARTILE VARIABLE
        return unless chart_variable_json = get_variable(chart_type)
        return unless domain_json = get_domain(json)

        title = "#{json['display_name']} by #{chart_variable_json['display_name']}"
        subtitle = "By Visit"
        # categories = ["Quartile One", "Quartile Two", "Quartile Three", "Quartile Four"]
        units = 'percent'
        series = []

        filtered_subjects = subjects.select{ |s| s.send(method) != nil and s.send(chart_type) != nil }.sort_by(&chart_type.to_sym)

        categories = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
          bucket = filtered_subjects.send(quartile).collect(&chart_type.to_sym)
          "#{bucket.min} to #{bucket.max}"
        end

        domain_json.each do |option_hash|
          data = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            filtered_subjects.send(quartile).select{ |s| s.send(method) == option_hash['value'] }.count
          end

          series << { name: option_hash['display_name'], data: data } unless filtered_subjects.size == 0
        end

        { title: title, subtitle: subtitle, categories: categories, units: units, series: series, stacking: 'percent' }
      end

      def self.chart_arbitrary_by_quartile(chart_type, subjects, json, method, visits)
        # CHART TYPE IS THE QUARTILE VARIABLE
        return unless chart_variable_json = get_variable(chart_type)
        return chart_arbitrary_choices_by_quartile(chart_type, subjects, json, method) if json['type'] == 'choices'

        title = "#{json['display_name']} by #{chart_variable_json['display_name']}"
        subtitle = "By Visit"
        categories = ["Quartile One", "Quartile Two", "Quartile Three", "Quartile Four"]
        units = json["units"]
        series = []

        series = []

        visits.each do |visit_display_name, visit_value|
          data = []
          filtered_subjects = subjects.select{ |s| s._visit == visit_value and s.send(method) != nil and s.send(chart_type) != nil }.sort_by(&chart_type.to_sym)

          [:quartile_one, :quartile_two, :quartile_three, :quartile_four].each do |quartile|
            array = filtered_subjects.send(quartile).collect(&method.to_sym)
            data << {       y: (array.mean.round(1) rescue 0.0),
                         stddev: ("%0.1f" % array.standard_deviation rescue ''),
                         median: ("%0.1f" % array.median rescue ''),
                            min: ("%0.1f" % array.min rescue ''),
                            max: ("%0.1f" % array.max rescue ''),
                              n: array.n }
          end

          series << { name: visit_display_name, data: data } unless filtered_subjects.size == 0
        end

        { title: title, subtitle: subtitle, categories: categories, units: units, series: series }
      end

      def self.table_arbitrary_by_quartile(chart_type, subjects, json, method, subtitle = nil)
        return table_arbitrary_choices_by_quartile(chart_type, subjects, json, method, subtitle) if json['type'] == 'choices'
        # CHART TYPE IS THE QUARTILE VARIABLE
        return unless chart_variable_json = get_variable(chart_type)


        headers = [
          [""] + Spout::Helpers::ArrayStatistics::calculations.collect{|calculation_label, calculation_method| calculation_label} + ["Total"]
        ]

        filtered_subjects = subjects.select{ |s| s.send(method) != nil and s.send(chart_type) != nil }.sort_by(&chart_type.to_sym)

        rows = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
          bucket = filtered_subjects.send(quartile)
          row_subjects = bucket.collect(&method.to_sym)
          data = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
            TableFormatting::format_number(row_subjects.send(calculation_method), calculation_type, calculation_format)
          end

          row_name = if row_subjects.size == 0
            quartile.to_s.capitalize.gsub('_one', ' One').gsub('_two', ' Two').gsub('_three', ' Three').gsub('_four', ' Four')
          else
            "#{bucket.collect(&chart_type.to_sym).min} to #{bucket.collect(&chart_type.to_sym).max} #{chart_variable_json['units']}"
          end

          [row_name] + data + [{ text: TableFormatting::format_number(row_subjects.count, :count), style: 'font-weight:bold'}]
        end

        total_values = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
          total_count = filtered_subjects.collect(&method.to_sym).send(calculation_method)
          { text: TableFormatting::format_number(total_count, calculation_type, calculation_format), style: "font-weight:bold" }
        end

        footers = [
          [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: TableFormatting::format_number(filtered_subjects.count, :count), style: 'font-weight:bold'}]
        ]

        { title: "#{chart_variable_json['display_name']} vs #{json['display_name']}", subtitle: subtitle, headers: headers, footers: footers, rows: rows }

      end

      def self.table_arbitrary_choices_by_quartile(chart_type, subjects, json, method, subtitle)
        # CHART TYPE IS THE QUARTILE VARIABLE
        return unless chart_variable_json = get_variable(chart_type)
        return unless domain_json = get_domain(json)

        filtered_subjects = subjects.select{ |s| s.send(method) != nil and s.send(chart_type) != nil }.sort_by(&chart_type.to_sym)

        categories = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
          bucket = filtered_subjects.send(quartile).collect(&chart_type.to_sym)
          "#{bucket.min} to #{bucket.max} #{chart_variable_json['units']}"
        end

        headers = [
          [""] + categories + ["Total"]
        ]

        rows = []

        rows = domain_json.collect do |option_hash|
          row_subjects = filtered_subjects.select{ |s| s.send(method) == option_hash['value'] }

          data = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            bucket = filtered_subjects.send(quartile).select{ |s| s.send(method) == option_hash['value'] }
            TableFormatting::format_number(bucket.count, :count)
          end

          [option_hash['display_name']] + data + [{ text: TableFormatting::format_number(row_subjects.count, :count), style: 'font-weight:bold'}]
        end


        total_values = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
          { text: TableFormatting::format_number(filtered_subjects.send(quartile).count, :count), style: "font-weight:bold" }
        end

        footers = [
          [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: TableFormatting::format_number(filtered_subjects.count, :count), style: 'font-weight:bold'}]
        ]

        { title: "#{json['display_name']} vs #{chart_variable_json['display_name']}", subtitle: subtitle, headers: headers, footers: footers, rows: rows }
      end


      def self.chart_arbitrary_choices(chart_type, subjects, json, method)
        return unless chart_variable_json = get_variable(chart_type)
        return unless chart_variable_domain = Spout::Commands::JsonChartsAndTables::domain_array(chart_type)
        return unless domain_json = get_domain(json)


        title = "#{json['display_name']} by #{chart_variable_json['display_name']}"
        subtitle = "By Visit"
        categories = chart_variable_domain.collect{|a| a[0]}
        units = 'percent'
        series = []


        domain_json.each do |option_hash|
          domain_values = subjects.select{ |s| s.send(method) == option_hash['value'] }

          data = chart_variable_domain.collect do |display_name, value|
            domain_values.select{ |s| s.send(chart_type) == value }.count
          end
          series << { name: option_hash['display_name'], data: data }
        end

        { title: title, subtitle: subtitle, categories: categories, units: units, series: series, stacking: 'percent' }
      end

      def self.chart_arbitrary(chart_type, subjects, json, method, visits)
        return unless chart_variable_json = get_variable(chart_type)
        return unless chart_variable_domain = Spout::Commands::JsonChartsAndTables::domain_array(chart_type)
        return chart_arbitrary_by_quartile(chart_type, subjects, json, method, visits) if ['numeric', 'integer'].include?(chart_variable_json['type'])

        return chart_arbitrary_choices(chart_type, subjects, json, method) if json['type'] == 'choices'

        title = "#{json['display_name']} by #{chart_variable_json['display_name']}"
        subtitle = "By Visit"
        categories = []
        units = json["units"]
        series = []

        data = []

        visits.each do |visit_display_name, visit_value|
          visit_subjects = subjects.select{ |s| s._visit == visit_value and s.send(method) != nil }
          if visit_subjects.count > 0
            chart_variable_domain.each_with_index do |(display_name, value), index|
              values = visit_subjects.select{|s| s.send(chart_type) == value }.collect(&method.to_sym)
              data[index] ||= []
              data[index] << (values.mean.round(2) rescue 0.0)
            end
            categories << visit_display_name
          end
        end

        chart_variable_domain.each_with_index do |(display_name, value), index|
          series << { name: display_name, data: data[index] }
        end

        { title: title, subtitle: subtitle, categories: categories, units: units, series: series }
      end


      def self.table_arbitrary(chart_type, subjects, json, method, subtitle = nil)
        return unless chart_variable_json = get_variable(chart_type)
        return unless chart_variable_domain = Spout::Commands::JsonChartsAndTables::domain_array(chart_type)
        return table_arbitrary_by_quartile(chart_type, subjects, json, method, subtitle) if ['numeric', 'integer'].include?(chart_variable_json['type'])
        return table_arbitrary_choices(chart_type, subjects, json, method, subtitle) if json['type'] == 'choices'

        headers = [
          [""] + Spout::Helpers::ArrayStatistics::calculations.collect{|calculation_label, calculation_method| calculation_label} + ["Total"]
        ]

        filtered_subjects = subjects.select{ |s| s.send(chart_type) != nil }

        rows = chart_variable_domain.collect do |display_name, value|
          row_subjects = filtered_subjects.select{ |s| s.send(chart_type) == value }

          row_cells = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
            count = row_subjects.collect(&method.to_sym).send(calculation_method)
            (count == 0 && calculation_method == :count) ? { text: '-', class: 'text-muted' } : TableFormatting::format_number(count, calculation_type, calculation_format)
          end

          [display_name] + row_cells + [{ text: TableFormatting::format_number(row_subjects.count, :count), style: 'font-weight:bold'}]
        end

        total_values = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
          total_count = filtered_subjects.collect(&method.to_sym).send(calculation_method)
          { text: TableFormatting::format_number(total_count, calculation_type, calculation_format), style: "font-weight:bold" }
        end

        footers = [
          [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: TableFormatting::format_number(filtered_subjects.count, :count), style: 'font-weight:bold'}]
        ]

        { title: "#{chart_variable_json['display_name']} vs #{json['display_name']}", subtitle: subtitle, headers: headers, footers: footers, rows: rows }

      end

      def self.table_arbitrary_choices(chart_type, subjects, json, method, subtitle)
        return unless chart_variable_json = get_variable(chart_type)
        return unless chart_variable_domain = Spout::Commands::JsonChartsAndTables::domain_array(chart_type)
        return unless domain_json = get_domain(json)

        headers = [
          [""] + chart_variable_domain.collect{|display_name, value| display_name} + ["Total"]
        ]

        filtered_subjects = subjects.select{ |s| s.send(chart_type) != nil }

        rows = domain_json.collect do |option_hash|
          row_subjects = filtered_subjects.select{ |s| s.send(method) == option_hash['value'] }
          row_cells = chart_variable_domain.collect do |display_name, value|
            count = row_subjects.select{ |s| s.send(chart_type) == value }.count
            count > 0 ? TableFormatting::format_number(count, :count) : { text: '-', class: 'text-muted' }
          end

          total = row_subjects.count

          [option_hash['display_name']] + row_cells + [total == 0 ? { text: '-', class: 'text-muted' } : { text: TableFormatting::format_number(total, :count), style: 'font-weight:bold'}]
        end

        if filtered_subjects.select{|s| s.send(method) == nil }.count > 0
          unknown_values = chart_variable_domain.collect do |display_name, value|
            { text: TableFormatting::format_number(filtered_subjects.select{ |s| s.send(chart_type) == value and s.send(method) == nil }.count, :count), class: 'text-muted' }
          end
          rows << [{ text: 'Unknown', class: 'text-muted'}] + unknown_values + [ { text: filtered_subjects.select{|s| s.send(method) == nil}.count.to_s, style: 'font-weight:bold', class: 'text-muted' } ]
        end



        total_values = chart_variable_domain.collect do |display_name, value|
          total_count = filtered_subjects.select{|s| s.send(chart_type) == value }.count
          { text: (total_count == 0 ? "-" : TableFormatting::format_number(total_count, :count)), style: "font-weight:bold" }
        end

        footers = [
          [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: TableFormatting::format_number(filtered_subjects.count, :count), style: 'font-weight:bold'}]
        ]

        { title: "#{json['display_name']} vs #{chart_variable_json['display_name']}", subtitle: subtitle, headers: headers, footers: footers, rows: rows }
      end


      def self.chart_histogram_choices(chart_type, subjects, json, method)
        return unless domain_json = get_domain(json)
        return unless chart_variable_json = get_variable(chart_type)
        return unless chart_variable_domain = Spout::Commands::JsonChartsAndTables::domain_array(chart_type)


        title = "#{json['display_name']}"
        subtitle = "By Visit"

        categories = domain_json.collect{|option_hash| option_hash['display_name']}

        units = "Subjects"
        series = []

        chart_variable_domain.each do |display_name, value|
          visit_subjects = subjects.select{ |s| s.send(chart_type) == value and s.send(method) != nil }.collect(&method.to_sym)
          next unless visit_subjects.size > 0

          data = []

          domain_json.each do |option_hash|
            data << visit_subjects.select{ |v| v == option_hash['value'] }.count
          end

          series << { name: display_name, data: data }
        end

        { title: title, subtitle: subtitle, categories: categories, units: units, series: series }
      end

      def self.chart_histogram(chart_type, subjects, json, method)
        return chart_histogram_choices(chart_type, subjects, json, method) if json['type'] == 'choices'
        return unless chart_variable_json = get_variable(chart_type)
        return unless chart_variable_domain = Spout::Commands::JsonChartsAndTables::domain_array(chart_type)

        title = "#{json['display_name']}"
        subtitle = "By Visit"
        categories = []
        units = "Subjects"
        series = []

        all_subject_values = subjects.collect(&method.to_sym).compact.sort
        return nil if all_subject_values.count == 0
        buckets = continuous_buckets(all_subject_values)

        categories = buckets.collect{|b| "#{b[0].round(1)} to #{b[1].round(1)}"}

        chart_variable_domain.each do |display_name, value|
          visit_subjects = subjects.select{ |s| s.send(chart_type) == value and s.send(method) != nil }.collect(&method.to_sym).sort
          next unless visit_subjects.size > 0

          data = []

          visit_subjects.group_by{|v| get_bucket(buckets, v) }.each do |key, values|
            data[categories.index(key)] = values.count if categories.index(key)
          end

          series << { name: display_name, data: data }
        end

        { title: title, subtitle: subtitle, categories: categories, units: units, series: series }
      end

    end
  end
end
