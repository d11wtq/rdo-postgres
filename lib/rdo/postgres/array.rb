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
      # Convert the Array to the format used by PostgreSQL.
      #
      # @return [String]
      #   a postgresql array string
      def to_s
        "{#{map(&method(:format_value)).join(",")}}"
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
        return "NULL" if v.nil?

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
        return nil if s == "NULL"

        if s[0] == '"'
          s[1...-1].gsub(/\\(.)/, "\\1")
        else
          s
        end
      end

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
            a.replace(str[1...-1].split(",").map(&a.method(:parse_value)))
          end
        end
      end
    end
  end
end
