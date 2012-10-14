##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Ruby handling for date[] type in PostgreSQL.
    class Array::Date < Array
      def parse_value(s)
        RDO::Util.date(s)
      end
    end
  end
end

