# encoding: utf-8

##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Connection to the Postgres server.
    #
    # Almost all default behaviour is overloaded.
    class Connection < RDO::Connection
      # implementation defined by C extension

      private

      # Passed to PQconnectdb().
      #
      # e.g. "host=localhost user=bob password=secret dbname=bobs_db"
      def connect_db_string
        {
          host:     options[:host],
          port:     options[:port],
          dbname:   options[:database],
          user:     options[:user],
          password: options[:password]
        }.reject{|k,v| v.nil?}.map{|pair| pair.join("=")}.join(" ")
      end
    end
  end
end
