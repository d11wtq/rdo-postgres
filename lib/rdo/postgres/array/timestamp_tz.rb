##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Ruby handling for timestamptz[] type in PostgreSQL.
    class Array::TimestampTZ < Array
      def parse_value(s)
        RDO::Util.date_time_with_zone(s)
      end
    end
  end
end
