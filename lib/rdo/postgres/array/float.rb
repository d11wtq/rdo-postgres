##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Ruby handling for float[] type in PostgreSQL.
    class Array::Float < Array
      def parse_value(s)
        case s
        when "Infinity"
          ::Float::INFINITY
        when "-Infinity"
          -::Float::INFINITY
        when "NaN"
          ::Float::NAN
        else
          s.to_f
        end
      end

      def format_value(v)
        v.to_s
      end
    end
  end
end
