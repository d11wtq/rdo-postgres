##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Utility class used to handle PostgreSQL arrays.
    #
    # The default implementation assumes only String support.
    # Subclasses override #parse_value and #format_value for typed-arrays.
    #
    # @example Turn a Ruby Array into a PostgreSQL array String
    #   RDO::Postgres::Array.new(original).to_s
    #   # => {"John Smith","Sarah Doe"}
    #
    # @example Turn a PostgreSQL array String into a Ruby Array
    #   RDO::Postgres::Array.parse('{"John Smith","Sarah Doe"}').to_a
    #   # => ["John Smith", "Sarah Doe"]
    class Array < ::Array
      class << self
        # Read a PostgreSQL array in its string form.
        #
        # @param [String] str
        #   an array string from postgresql
        #
        # @return [Array]
        #   a Ruby Array for this string
        def parse(str)
          new.tap do |a|
            a.replace(str[1...-1].split(",").map(&a.method(:parse_value_or_null)))
          end
        end
      end

      # Convert the Array to the format used by PostgreSQL.
      #
      # @return [String]
      #   a postgresql array string
      def to_s
        "{#{map(&method(:format_value_or_null)).join(",")}}"
      end

      # Format an individual element in the Array for building into a String.
      #
      # The default implementation wraps quotes around the element.
      #
      # @param [Object] v
      #   the Ruby type in the Array
      #
      # @return [String]
      #   a String used to build the formatted array
      def format_value(v)
        %Q{"#{v.to_s.gsub('\\', '\\\\\\\\').gsub('"', '\\\\"')}"}
      end

      # Parse an individual element from the array.
      #
      # The default implementation parses as if it were text.
      # Subclasses should override this.
      #
      # @param [String] s
      #   the string form of the array element
      #
      # @return [Object]
      #   the Ruby value
      def parse_value(s)
        s[0] == '"' ? s[1...-1].gsub(/\\(.)/, "\\1") : s
      end

      private

      def format_value_or_null(v)
        v.nil? ? "NULL" : format_value(v)
      end

      def parse_value_or_null(s)
        s == "NULL" ? nil : parse_value(s)
      end
    end
  end
end
