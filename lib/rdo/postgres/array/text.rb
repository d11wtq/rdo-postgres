##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Ruby handling for text[] type in PostgreSQL.
    class Array::Text < Array
      # abstract class behaves as text anyway
    end
  end
end
