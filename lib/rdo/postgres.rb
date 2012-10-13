##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "rdo"

require "rdo/postgres/version"
require "rdo/postgres/driver"

require "rdo/postgres/array"
require "rdo/postgres/array/text"

# c extension
require "rdo_postgres/rdo_postgres"

# Register name variants for postgresql schemes
%w[postgres postgresql pgsql psql].each do |name|
  RDO::Connection.register_driver(name, RDO::Postgres::Driver)
end
