require 'spout/helpers/array_statistics'
require 'spout/helpers/table_formatting'

module Spout
  module Helpers
    class ChartTypes
      def self.get_bucket(buckets, value)
        return nil if buckets.size == 0 or not value.kind_of?(Numeric)
        buckets.each do |b|
          return "#{b[0]} to #{b[1]}" if value >= b[0] and value <= b[1]
        end
        if value <= buckets.first[0]
          "#{buckets.first[0]} to #{buckets.first[1]}"
        else
          "#{buckets.last[0]} to #{buckets.last[1]}"
        end
      end

      def self.continuous_buckets(values)
        values.select!{|v| v.kind_of? Numeric}
        return [] if values.count == 0
        minimum_bucket = values.min
        maximum_bucket = values.max
        max_buckets = 12
        bucket_size = ((maximum_bucket - minimum_bucket) / max_buckets.to_f)
        precision = (bucket_size == 0 ? 0 : [-Math.log10(bucket_size).floor, 0].max)

        buckets = []
        (0..(max_buckets-1)).to_a.each do |index|
          start = (minimum_bucket + index * bucket_size)
          stop = (start + bucket_size)
          buckets << [start.round(precision),stop.round(precision)]
        end
        buckets
      end

      def self.get_json(file_name, file_type)
        file = Dir.glob("#{file_type.to_s.downcase}s/**/#{file_name.to_s.downcase}.json", File::FNM_CASEFOLD).first
        json = JSON.parse(File.read(file)) rescue json = nil
        json
      end

      def self.get_variable(variable_name)
        get_json(variable_name, 'variable')
      end

      def self.get_domain(json)
        get_json(json['domain'], 'domain')
      end

      def self.domain_array(variable_name)
        variable_file = Dir.glob("variables/**/#{variable_name.to_s.downcase}.json", File::FNM_CASEFOLD).first
        json = JSON.parse(File.read(variable_file)) rescue json = nil
        if json
          domain_json = get_domain(json)
          domain_json ? domain_json.collect{|option_hash| [option_hash['display_name'], option_hash['value']]} : []
        else
          []
        end
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
        all_subject_values = filtered_subjects.collect(&method.to_sym).compact.sort
        domain_json = remove_unused_missing_codes_from_domain(domain_json, all_subject_values.uniq)

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

      def self.table_arbitrary(chart_type, subjects, json, method, subtitle = nil)
        return unless chart_variable_json = get_variable(chart_type)
        return unless chart_variable_domain = domain_array(chart_type)
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
        return unless chart_variable_domain = domain_array(chart_type)
        return unless domain_json = get_domain(json)

        headers = [
          [""] + chart_variable_domain.collect{|display_name, value| display_name} + ["Total"]
        ]

        filtered_subjects = subjects.select{ |s| s.send(chart_type) != nil }

        all_subject_values = filtered_subjects.collect(&method.to_sym).compact.sort
        domain_json = remove_unused_missing_codes_from_domain(domain_json, all_subject_values.uniq)

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
          rows << [{ text: 'Unknown', class: 'text-muted'}] + unknown_values + [ { text: TableFormatting::format_number(filtered_subjects.select{|s| s.send(method) == nil}.count, :count), style: 'font-weight:bold', class: 'text-muted' } ]
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

      def self.remove_unused_missing_codes_from_domain(domain_json, unique_subject_values)
        domain_json.select{|option_hash| option_hash['missing'] != true or (option_hash['missing'] == true and unique_subject_values.include?(option_hash['value']))}
      end

    end
  end
end
