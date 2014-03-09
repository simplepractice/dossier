module Dossier
  class Result
    include Enumerable

    attr_accessor :report, :adapter_results

    def initialize(adapter_results, report)
      self.adapter_results = adapter_results
      self.report          = report
    end

    def raw_headers
      @raw_headers ||= adapter_results.headers
    end

    def headers
      raise NotImplementedError.new("#{self.class.name} must implement `headers', use `raw_headers' for adapter headers")
    end

    def body
      size = rows.length - report.options[:footer].to_i
      @body ||= size < 0 ? [] : rows.first(size)
    end

    def footers
      @footer ||= rows.last(report.options[:footer].to_i)
    end

    def rows
      @rows ||= to_a
    end

    def arrays
      @arrays ||= [headers] + rows
    end

    def hashes
      return @hashes if defined?(@hashes)
      @hashes = rows.map { |row| row_hash(row) }
    end

    # this is the method that creates the individual hash entry
    # hashes should always use raw headers
    def row_hash(row)
      Hash[self.report.columns.map {|v| [v,row.send(v)]}]
    end

    def each
      raise NotImplementedError.new("#{self.class.name} must define `each`")
    end

    class Formatted < Result

      def headers
              @formatted_headers ||= self.report.columns.map { |h| report.format_header(h) }
      end

      def each
        adapter_results.rows.each { |row| yield format(row) }
      end

      def format(row)
       
        self.report.columns.each_with_index.map do |value, i|
          
          if row.is_a?(ActiveRecord::Base)
            column = value
            method = "format_#{column}"
          
            args = [column]
          #  puts "ARITY #{column}  #{row.method(column).arity}"
            if (row.method(column).arity == -1  rescue false)          
               args << self.report.options
            end            
            value  = row.public_send(*args)
          else
            column = report.columns[i]
            method = "format_#{column}"
          end

          if report.respond_to?(method)
            args = [method, value]
            # Provide the row as context if the formatter takes two arguments
            if report.method(method).arity == 2
              if row.is_a?(ActiveRecord::Base) 
                args << row
              else
                 args << row_hash(row) 
              end
            end
            report.public_send(*args)
          else
            report.format_column(column, value)
          end
        end
      end
 
    end

    class Unformatted < Result
      def each
        adapter_results.rows.each { |row| yield row }
      end

      def headers
        raw_headers
      end
    end

  end
end
