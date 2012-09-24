# encoding: utf-8

require "mkmf"

if ENV["CC"]
  RbConfig::MAKEFILE_CONFIG["CC"] = ENV["CC"]
end

def config_value(type)
  IO.popen("pg_config --#{type}").readline.chomp rescue nil
end

def have_build_env
  [
    have_library("pq") || have_library("libpq"),
    have_header("libpq-fe.h"),
    have_header("postgres.h"),
    have_header("catalog/pg_type.h")
  ].all?
end

dir_config(
  "postgres",
  config_value("includedir-server"),
  config_value("libdir")
)

dir_config(
  "libpq",
  config_value("includedir"),
  config_value("libdir")
)

unless have_build_env
  puts "Unable to find postgresql libraries and headers. Not building."
  exit(1)
end

create_makefile("rdo_postgres/rdo_postgres")
