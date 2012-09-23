##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module RDO
  module Postgres
    # Driver for the Postgres server.
    #
    # All default behaviour is overloaded.
    class Driver < RDO::Driver
      # most implementation defined by C extension

      # Internally this driver uses prepared statements.
      #
      # @param [String] stmt
      #   the statement to execute
      #
      # @param [Object...] *args
      #   bind parameters to execute with
      #
      # @return [RDO::Result]
      #   a result containing any tuples and query info
      def execute(stmt, *args)
        prepare(stmt).execute(*args)
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
          connect_timeout: options[:connect_timeout]
        }.reject{|k,v| v.nil?}.map{|pair| pair.join("=")}.join(" ")
      end

      def after_open
        set_time_zone
        set_encoding
      end

      def set_time_zone
        if options[:time_zone]
          execute("SET TIME ZONE '#{options[:time_zone]}'")
        else
          execute("SET TIME ZONE interval '#{RDO::Util.system_time_zone}' hour to minute")
        end
      end

      def set_encoding
        execute("SET NAMES '#{encoding}'")
      end

      def encoding
        options.fetch(:encoding, "utf-8")
      end
    end
  end
end
