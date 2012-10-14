##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Ruby handling for timestamp[] type in PostgreSQL.
    class Array::Timestamp < Array
      def parse_value(s)
        RDO::Util.date_time_without_zone(s)
      end
    end
  end
end
