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
    # All default behaviour is overloaded.
    class Connection < RDO::Connection
      # implementation defined by C extension
      def intialize(options)
        super
        set_time_zone
      end

      private

      # Passed to PQconnectdb().
      #
      # e.g. "host=localhost user=bob password=secret dbname=bobs_db"
      def connect_db_string
        {
          host:            options[:host],
          port:            options[:port],
          dbname:          options[:database],
          user:            options[:user],
          password:        options[:password],
          client_encoding: options[:encoding],
          connect_timeout: options[:connect_timeout]
        }.reject{|k,v| v.nil?}.map{|pair| pair.join("=")}.join(" ")
      end

      def set_time_zone
        if options[:time_zone]
          execute "SET TIME ZONE '#{options[:time_zone]}'"
        else
          execute "SET TIME ZONE interval '#{detect_time_zone}' hour to minute"
        end
      end

      def detect_time_zone
        require "date" unless defined? DateTime
        DateTime.now.zone
      end
    end
  end
end
