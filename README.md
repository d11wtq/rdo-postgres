# RDO PostgreSQL Driver

This is the PostgreSQL driver for [RDO—Ruby Data Objects]
(https://github.com/d11wtq/rdo).

[![Build Status](https://secure.travis-ci.org/d11wtq/rdo-postgres.png?branch=master)](http://travis-ci.org/d11wtq/rdo-postgres)

Refer to the [RDO project README](https://github.com/d11wtq/rdo) for full
usage information.

## Supported PostgreSQL version

This driver supports PostgreSQL versions >= 7.4.

Older versions are no longer supported by PostgreSQL in any case.

## Installation

Via rubygems:

    $ gem install rdo-postgres

Or add the following line to your application's Gemfile:

    gem "rdo-postgres"

And install with Bundler:

    $ bundle install

## Usage

The registered URI schemes are postgres://, postgresql:// and psql://.

``` ruby
require "rdo-postgres"

conn = RDO.connect("postgres://user:pass@localhost/dbname?encoding=utf-8")
```

### Type Support

If not listed below, the String form of the value will be returned. The
currently mapped types are tabled below:

<table>
  <thead>
    <tr>
      <th>PostgreSQL Type</th>
      <th>Ruby Type</th>
      <th>Notes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>null</th>
      <td>NilClass</td>
      <td></td>
    </tr>
    <tr>
      <th>boolean</th>
      <td>TrueClass, FalseClass</td>
      <td>The strings 't' and 'f' will work as inputs too</td>
    </tr>
    <tr>
      <th>text, char, varchar</th>
      <td>String</td>
      <td>The encoding specified on the connection is used</td>
    </tr>
    <tr>
      <th>bytea</th>
      <td>String</td>
      <td>The output encoding is set to ASCII-8BIT/BINARY</td>
    </tr>
    <tr>
      <th>integer, int4, int2, int8</th>
      <td>Fixnum</td>
      <td>Ruby may use a Bignum, if needed</td>
    </tr>
    <tr>
      <th>float, real, float4, float8</th>
      <td>Float</td>
      <td>NaN, Infinity and -Infinity are supported</td>
    </tr>
    <tr>
      <th>numeric, decimal</th>
      <td>BigDecimal</td>
      <td>NaN is supported</td>
    </tr>
    <tr>
      <th>date</th>
      <td>Date</td>
      <td></td>
    </tr>
    <tr>
      <th>timestamp</th>
      <td>DateTime</td>
      <td>Input may also be a Time; output times are in the system time zone</td>
    </tr>
    <tr>
      <th>timestamp with time zone</th>
      <td>DateTime</td>
      <td>Input may also be a Time</td>
    </tr>
    <tr>
      <th>array</th>
      <td>Array</td>
      <td>n-dimensional arrays of the types listed above are supported</td>
    </tr>
  </tbody>
</table>

### PostgreSQL style bind parameters

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

I'm particulary interested in patches surrounding support for arrays of
custom types, such as ENUMs (this is done by reading from pg_type, in an
efficient manner).

When sending pull requests, please use topic branches—don't send a pull
request from the master branch of your fork.

Contributors will be credited in this README.

## Copyright & Licensing

Written by Chris Corbyn.

Licensed under the MIT license. See the LICENSE file for full details.
