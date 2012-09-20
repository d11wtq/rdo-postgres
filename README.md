# RDO PostgreSQL Driver

This is the PostgreSQL driver for [RDO—Ruby Data Objects](https://github.com/d11wtq/rdo).

Refer to the RDO project [README](https://github.com/d11wtq/rdo) for usage
information.

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

## Contributing

If you find any bugs, please send a pull request if you think you can
fix it, or file in an issue in the issue tracker.

When sending pull requests, please use topic branches—don't send a pull
request from the master branch of your fork, as that may change
unintentionally.

Contributors will be credited in this README.

## Copyright & Licensing

Written by Chris Corbyn.

Licensed under the MIT license. See the LICENSE file for full details.
