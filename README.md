# RDO PostgreSQL Driver

This is the PostgreSQL driver for [RDO—Ruby Data Objects]
(https://github.com/d11wtq/rdo).

[![Build Status](https://secure.travis-ci.org/d11wtq/rdo-postgres.png?branch=master)](http://travis-ci.org/d11wtq/rdo-postgres)

Refer to the RDO project [README](https://github.com/d11wtq/rdo) for usage
information.

This driver cannot be used with PostgreSQL versions older than 7.4. Those
versions are no longer supported by PostgreSQL in any case.

## Installation

Via rubygems:

    $ gem install rdo-postgres

Or add the following line to your application's Gemfile:

    gem "rdo-postgres"

And install with Bundler:

    $ bundle install

## Usage

The registered URI schemes are postgres:// and postgresql://

``` ruby
require "rdo"
require "rdo-postgres"

conn = RDO.connect("postgres://user:pass@localhost/dbname?encoding=utf-8")
```

Alternatively, give the driver name as "postgres" or "postgresql" in an
options Hash.

``` ruby
conn = RDO.connect(
  driver:    "postgresql",
  host:      "localhost",
  user:      "user",
  passsword: "pass",
  database:  "dbname",
  encoding:  "utf-8"
)
```

### Type Support

If not listed below, the String form of the value will be returned. The
currently mapped types are:

  - NULL -> nil
  - BOOLEAN -> TrueClass/FalseClass
  - TEXT -> String
  - VARCHAR -> String
  - CHAR -> String
  - BYTEA -> String
  - INTEGER -> Fixnum
  - INT2 -> Fixnum
  - INT4 -> Fixnum
  - INT8 -> Fixnum
  - FLOAT/REAL -> Float
  - FLOAT4 -> Float
  - FLOAT8 -> Float
  - NUMERIC/DECIMAL -> BigDecimal
  - DATE -> Date
  - TIMESTAMP -> DateTime (in the system time zone)
  - TIMESTAMPTZ -> DateTime (in the specified time zone)

All 1-dimensional Arrays of the above listed are also available. Support for
multi-dimensional Arrays is planned immediately. Support for custom-typed
Arrays is coming.

### Bind parameters support

PostgreSQL uses $1, $2 etc for bind parameters. RDO uses '?'. You can use
either, but you **cannot** mix both styles in the same query, or you will
get errors.

These are ok:

``` ruby
conn.execute("SELECT * FROM users WHERE banned = ? AND created_at > ?", true, 1.week.ago)
conn.execute("SELECT * FROM users WHERE banned = $1 AND created_at > $2", true, 1.week.ago)
```

This is **not ok**:

``` ruby
conn.execute("SELECT * FROM users WHERE banned = $1 AND created_at > ?", true, 1.week.ago)
```

## Contributing

If you find any bugs, please send a pull request if you think you can
fix it, or file in an issue in the issue tracker.

I'm particulary interested in patches surrounding support for built-in type
arrays, multi-dimensional arrays and arrays of custom types, such as ENUMs
(in order of difficulty/preference).

When sending pull requests, please use topic branches—don't send a pull
request from the master branch of your fork, as that may change
unintentionally.

Contributors will be credited in this README.

## Copyright & Licensing

Written by Chris Corbyn.

Licensed under the MIT license. See the LICENSE file for full details.
