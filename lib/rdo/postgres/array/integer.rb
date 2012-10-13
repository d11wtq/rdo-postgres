##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Ruby handling for integer[] type in PostgreSQL.
    class Array::Integer < Array
      def parse_value(s)
        s.to_i
      end

      def format_value(v)
        v.to_s
      end
    end
  end
end
