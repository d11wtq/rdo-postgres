##
# RDO PostgreSQL driver.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "rdo"
require "rdo/postgres/version"
require "rdo/postgres/driver"
# C extension: if anybody knows how to put this at
# rdo/postgres/rdo_postgres.so, let me know
require "rdo_postgres/rdo_postgres"

# Register name variants for postgresql schemes
%w[postgres postgresql].each do |name|
  RDO::Connection.register_driver(name, RDO::Postgres::Driver)
end
