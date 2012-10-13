##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Ruby handling for bytea[] type in PostgreSQL.
    class Array::Bytea < Array
      def parse_value(s)
        # defined in ext/rdo_postgres/arrays.c
      end

      def format_value(v)
        # defined in ext/rdo_postgres/arrays.c
      end
    end
  end
end

