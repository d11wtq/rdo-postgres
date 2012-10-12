##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Utility methods that are easier to write in Ruby than in C.
    #
    # There are no real performance benefits to writing these routines in C.
    module Util
      class << self
        # Take a postgresql integer[] string and return the Ruby Array.
        #
        # @param [String] s
        #   the internal PostgreSQL representation
        #
        # @return [Array]
        #   an Array of Fixnums
        def parse_int_array(s)
          s[1..-1].split(",").map(&:to_i).to_a
        end
      end
    end
  end
end
