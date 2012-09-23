# RDO PostgreSQL Driver

This is the PostgreSQL driver for [RDO—Ruby Data Objects]
(https://github.com/d11wtq/rdo).

Refer to the RDO project [README](https://github.com/d11wtq/rdo) for usage
information.

This driver cannot be used with Postgres versions older than 7.4, since the
protocol has changed and this driver takes advantage of newer protocol (3.0)
features.

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

Contributions to support older versions of PostgreSQL (< 7.4) welcomed,
though if the changes required break the native support for newer versions
pull requests will not be accepted. It is possible to write a separate
driver for older versions of PostgreSQL and register it under the driver
name 'postgresql' instead of this one if that is preferable. Alternatively,
use an explicit name that indicates legacy compatibility, such as
'postgres73'.

If you find any bugs, please send a pull request if you think you can
fix it, or file in an issue in the issue tracker.

When sending pull requests, please use topic branches—don't send a pull
request from the master branch of your fork, as that may change
unintentionally.

Contributors will be credited in this README.

## Copyright & Licensing

Written by Chris Corbyn.

Licensed under the MIT license. See the LICENSE file for full details.
