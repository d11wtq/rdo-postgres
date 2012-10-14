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
        # Shortcut for the constructor.
        #
        # @param [Object...] *args
        #   a list of objects to put inside the Array
        #
        # @return [Array]
        #   a newly initialzed Array
        def [](*args)
          new(args)
        end

        # Read a PostgreSQL array in its string form.
        #
        # @param [String] str
        #   an array string from PostgreSQL
        #
        # @return [Array]
        #   a Ruby Array for this string
        def parse(str)
          # defined in ext/rdo_postgres/arrays.c
        end
      end

      # Initialize a new Array, coercing any sub-Arrays to the same type.
      #
      # @param [Array] arr
      #   the Array to wrap
      def initialize(arr = 0)
        if ::Array === arr
          super(arr.map{|v| ::Array === v ? self.class.new(v) : v})
        else
          super
        end
      end

      # Convert the Array to the format used by PostgreSQL.
      #
      # @return [String]
      #   a PostgreSQL array string
      def to_s
        "{#{map(&method(:format_value_or_null)).join(",")}}"
      end

      # Convert the Array to a standard Ruby Array.
      #
      # @return [::Array]
      #   a Ruby Array
      def to_a
        super.map{|v| Array === v ? v.to_a : v}
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
        case v
        when nil   then "NULL"
        when Array then v.to_s
        else format_value(v)
        end
      end

      def parse_value_or_null(s)
        s == "NULL" ? nil : parse_value(s)
      end
    end
  end
end
