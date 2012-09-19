##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "rdo"
require "rdo/postgres/version"
require "rdo/postgres/connection"
require "rdo/rdo_postgres" # c ext

# Register name variants for postgresql schemes
%w[postgres postgresql].each do |name|
  RDO::Connection.register_driver(name, RDO::Postgres::Connection)
end
