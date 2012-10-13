##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "bigdecimal"

module RDO
  module Postgres
    # Ruby handling for numeric[] type in PostgreSQL.
    class Array::Numeric < Array
      def parse_value(s)
        BigDecimal.new(s)
      end

      def format_value(v)
        v.to_s
      end
    end
  end
end
