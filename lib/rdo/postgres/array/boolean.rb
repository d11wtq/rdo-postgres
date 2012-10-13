##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Ruby handling for boolean[] type in PostgreSQL.
    class Array::Boolean < Array
      def parse_value(s)
        s[0] == "t"
      end

      def format_value(v)
        (!!v).to_s
      end
    end
  end
end
