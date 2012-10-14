require "spec_helper"
require "bigdecimal"
require "date"

describe RDO::Postgres::Driver, "bind parameter support" do
  let(:connection) { RDO.connect(connection_uri) }
  let(:table)      { "" }

  before(:each) do
    connection.execute("DROP SCHEMA IF EXISTS rdo_test CASCADE")
    connection.execute("CREATE SCHEMA rdo_test")
    connection.execute("SET search_path = rdo_test")
    connection.execute(table)
  end

  after(:each) do
    begin
      connection.execute("DROP SCHEMA IF EXISTS rdo_test CASCADE")
    rescue RDO::Exception => e
      # accept that tests may fail for other reasons, don't also fail on cleanup
    ensure
      connection.close rescue nil
    end
  end

  describe "String param" do
    context "against a text field" do
      let(:table) { "CREATE TABLE test (id serial primary key, name text)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (name) VALUES (?) RETURNING *",
          "Fern Cotton"
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, name: "Fern Cotton"}
      end
    end

    context "against an integer field" do
      let(:table) { "CREATE TABLE test (id serial primary key, age integer)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (age) VALUES (?) RETURNING *", "32").first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, age: 32}
      end
    end

    context "against a boolean field" do
      let(:table) { "CREATE TABLE test (id serial primary key, rad boolean)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (rad) VALUES (?) RETURNING *", "true").first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, rad: true}
      end
    end

    context "against a float field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score float)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (score) VALUES (?) RETURNING *", "85.4").first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, score: 85.4}
      end
    end

    context "against a decimal field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score decimal)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (score) VALUES (?) RETURNING *", "85.4").first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, score: BigDecimal("85.4")}
      end
    end

    context "against a date field" do
      let(:table) { "CREATE TABLE test (id serial primary key, dob date)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (dob) VALUES (?) RETURNING *", "1983-05-03").first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, dob: Date.new(1983, 5, 3)}
      end
    end

    context "against a timestamp field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamp)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (created_at) VALUES (?) RETURNING *",
          "2012-09-22 10:00:05"
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, created_at: DateTime.new(2012, 9, 22, 10, 0, 5, DateTime.now.zone)}
      end
    end

    context "against a timestamptz field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamptz)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (created_at) VALUES (?) RETURNING *",
          "2012-09-22 10:00:05 -5"
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, created_at: DateTime.new(2012, 9, 22, 10, 0, 5, "-5")}
      end
    end

    context "against a bytea field" do
      let(:table) { "CREATE TABLE test (id serial primary key, salt bytea)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (salt) VALUES (?) RETURNING *", "\x00\x01\x02"
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, salt: "\x00\x01\x02"}
      end

      context "that is empty" do
        let(:table) { "CREATE TABLE test (id serial primary key, salt bytea)" }
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (salt) VALUES (?) RETURNING *", ""
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, salt: ""}
        end
      end
    end
  end

  describe "Fixnum param" do
    context "against an integer field" do
      let(:table) { "CREATE TABLE test (id serial primary key, age integer)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (age) VALUES (?) RETURNING *",
          42
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, age: 42}
      end
    end

    context "against a text field" do
      let(:table) { "CREATE TABLE test (id serial primary key, name text)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (name) VALUES (?) RETURNING *",
          42
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, name: "42"}
      end
    end

    context "against a float field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score float)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (score) VALUES (?) RETURNING *",
          42
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, score: 42.0}
      end
    end

    context "agsinst a decimal field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score decimal)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (score) VALUES (?) RETURNING *",
          42
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, score: BigDecimal("42")}
      end
    end

    context "against a boolean field" do
      let(:table) { "CREATE TABLE test (id serial primary key, rad boolean)" }

      context "when it is 0" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (rad) VALUES (?) RETURNING *",
            0
          ).first
        end

        it "is inferred correctly (false)" do
          tuple.should == {id: 1, rad: false}
        end
      end

      context "when it is 1" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (rad) VALUES (?) RETURNING *",
            1
          ).first
        end

        it "is inferred correctly (true)" do
          tuple.should == {id: 1, rad: true}
        end
      end
    end

    context "against a bytea field" do
      let(:table) { "CREATE TABLE test (id serial primary key, salt bytea)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (salt) VALUES (?) RETURNING *",
          42
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, salt: "42"}
      end
    end
  end

  describe "Float param" do
    context "against a float field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score float)" }

      context "when it is NaN" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (score) VALUES (?) RETURNING *",
            Float::NAN
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, score: Float::NAN}
        end
      end

      context "when it is Infinity" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (score) VALUES (?) RETURNING *",
            Float::INFINITY
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, score: Float::INFINITY}
        end
      end

      context "when it is -Infinity" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (score) VALUES (?) RETURNING *",
            -Float::INFINITY
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, score: -Float::INFINITY}
        end
      end

      context "when it is a real number" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (score) VALUES (?) RETURNING *",
            12.5
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, score: 12.5}
        end
      end
    end

    context "against a text field" do
      let(:table) { "CREATE TABLE test (id serial primary key, name text)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (name) VALUES (?) RETURNING *",
          12.5
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, name: "12.5"}
      end
    end

    context "against a decimal field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score decimal)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (score) VALUES (?) RETURNING *",
          12.2
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, score: BigDecimal("12.2")}
      end
    end
  end

  describe "BigDecimal param" do
    context "against a decimal field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score decimal)" }

      context "when it is NaN" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (score) VALUES (?) RETURNING *",
            BigDecimal("NaN")
          ).first
        end

        it "is inferred correctly" do
          tuple[:score].should be_a_kind_of(BigDecimal)
          tuple[:score].should be_nan
        end
      end

      context "when it is a real number" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (score) VALUES (?) RETURNING *",
            BigDecimal("12.2")
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, score: BigDecimal("12.2")}
        end
      end
    end

    context "against a text field" do
      let(:table) { "CREATE TABLE test (id serial primary key, name text)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (name) VALUES (?) RETURNING *",
          BigDecimal("12.7")
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, name: BigDecimal("12.7").to_s}
      end
    end

    context "against a float field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score float)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (score) VALUES (?) RETURNING *",
          BigDecimal("12.7")
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, score: 12.7}
      end
    end
  end

  describe "Date param" do
    context "against a Date field" do
      let(:table) { "CREATE TABLE test (id serial primary key, dob date)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (dob) VALUES (?) RETURNING *",
          Date.new(1983, 5, 3)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, dob: Date.new(1983, 5, 3)}
      end
    end

    context "against a text field" do
      let(:table) { "CREATE TABLE test (id serial primary key, name text)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (name) VALUES (?) RETURNING *",
          Date.new(1983, 5, 3)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, name: "1983-05-03"}
      end
    end

    context "against a timestamp field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamp)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (created_at) VALUES (?) RETURNING *",
          Date.new(1983, 5, 3)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, created_at: DateTime.new(1983, 5, 3, 0, 0, 0, DateTime.now.zone)}
      end
    end

    context "against a timestamptz field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamptz)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (created_at) VALUES (?) RETURNING *",
          Date.new(1983, 5, 3)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, created_at: DateTime.new(1983, 5, 3, 0, 0, 0, DateTime.now.zone)}
      end
    end
  end

  describe "Time param" do
    context "against a timestamp field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamp)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (created_at) VALUES (?) RETURNING *",
          Time.new(2012, 9, 22, 5, 16, 58)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, created_at: DateTime.new(2012, 9, 22, 5, 16, 58, DateTime.now.zone)}
      end
    end

    context "against a timestamptz field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamptz)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (created_at) VALUES (?) RETURNING *",
          Time.new(2012, 9, 22, 5, 16, 58, "-07:00")
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, created_at: DateTime.new(2012, 9, 22, 5, 16, 58, "-07:00")}
      end
    end

    context "against a date field" do
      let(:table) { "CREATE TABLE test (id serial primary key, dob date)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (dob) VALUES (?) RETURNING *",
          Time.new(1983, 5, 3, 6, 13, 0)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, dob: Date.new(1983, 5, 3)}
      end
    end

    context "against a text field" do
      let(:table) { "CREATE TABLE test (id serial primary key, name text)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (name) VALUES (?) RETURNING *",
          Time.new(2012, 9, 22, 5, 16, 58)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, name: Time.new(2012, 9, 22, 5, 16, 58).to_s}
      end
    end
  end

  describe "DateTime param" do
    context "against a timestamp field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamp)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (created_at) VALUES (?) RETURNING *",
          DateTime.new(1983, 5, 3, 6, 13, 0)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, created_at: DateTime.new(1983, 5, 3, 6, 13, 0, DateTime.now.zone)}
      end
    end

    context "against a timestamptz field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamptz)" }

      context "with a time zone given" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (created_at) VALUES (?) RETURNING *",
            DateTime.new(1983, 5, 3, 6, 13, 0, "-07:00")
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, created_at: DateTime.new(1983, 5, 3, 6, 13, 0, "-07:00")}
        end
      end

      context "without a time zone given" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (created_at) VALUES (?) RETURNING *",
            DateTime.new(1983, 5, 3, 6, 13, 0)
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, created_at: DateTime.new(1983, 5, 3, 6, 13, 0)}
        end
      end
    end

    context "against a date field" do
      let(:table) { "CREATE TABLE test (id serial primary key, dob date)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (dob) VALUES (?) RETURNING *",
          DateTime.new(1983, 5, 3, 6, 13, 0)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, dob: Date.new(1983, 5, 3)}
      end
    end

    context "against a text field" do
      let(:table) { "CREATE TABLE test (id serial primary key, name text)" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (name) VALUES (?) RETURNING *",
          DateTime.new(1983, 5, 3, 6, 13, 0)
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, name: DateTime.new(1983, 5, 3, 6, 13, 0).to_s}
      end
    end
  end

  describe "nil param" do
    context "against a text field" do
      let(:table) { "CREATE TABLE test (id serial primary key, name text)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (name) VALUES (?) RETURNING *", nil).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, name: nil}
      end
    end

    context "against an integer field" do
      let(:table) { "CREATE TABLE test (id serial primary key, age integer)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (age) VALUES (?) RETURNING *", nil).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, age: nil}
      end
    end

    context "against a float field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score float)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (score) VALUES (?) RETURNING *", nil).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, score: nil}
      end
    end

    context "against a decimal field" do
      let(:table) { "CREATE TABLE test (id serial primary key, score decimal)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (score) VALUES (?) RETURNING *", nil).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, score: nil}
      end
    end

    context "against a boolean field" do
      let(:table) { "CREATE TABLE test (id serial primary key, rad boolean)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (rad) VALUES (?) RETURNING *", nil).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, rad: nil}
      end
    end

    context "against a date field" do
      let(:table) { "CREATE TABLE test (id serial primary key, dob date)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (dob) VALUES (?) RETURNING *", nil).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, dob: nil}
      end
    end

    context "against a timestamp field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamp)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (created_at) VALUES (?) RETURNING *", nil).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, created_at: nil}
      end
    end

    context "against a timestamptz field" do
      let(:table) { "CREATE TABLE test (id serial primary key, created_at timestamptz)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (created_at) VALUES (?) RETURNING *", nil).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, created_at: nil}
      end
    end

    context "against a bytea field" do
      let(:table) { "CREATE TABLE test (id serial primary key, salt bytea)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (salt) VALUES (?) RETURNING *", nil).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, salt: nil}
      end
    end
  end

  describe "Array param" do
    context "against a text[] field" do
      let(:table) { "CREATE TABLE test (id serial primary key, words text[])" }
      let(:tuple) do
        connection.execute("INSERT INTO test (words) VALUES (?) RETURNING *", ["apple", "orange"]).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, words: ["apple", "orange"]}
      end

      context "with embeddded quotes" do
        let(:tuple) do
          connection.execute("INSERT INTO test (words) VALUES (?) RETURNING *", ['"apple"']).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, words: ['"apple"']}
        end
      end

      context "with embeddded backslashes" do
        let(:tuple) do
          connection.execute("INSERT INTO test (words) VALUES (?) RETURNING *", ['\\apple']).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, words: ['\\apple']}
        end
      end

      context "with embedded nils" do
        let(:tuple) do
          connection.execute("INSERT INTO test (words) VALUES (?) RETURNING *", ["apple", nil]).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, words: ["apple", nil]}
        end
      end

      context "with embedded new lines" do
        let(:tuple) do
          connection.execute("INSERT INTO test (words) VALUES (?) RETURNING *", ["apple\norange"]).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, words: ["apple\norange"]}
        end
      end
    end

    context "against an integer[] field" do
      let(:table) { "CREATE TABLE test (id serial primary key, days integer[])" }
      let(:tuple) do
        connection.execute("INSERT INTO test (days) VALUES (?) RETURNING *", [4, 11]).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, days: [4, 11]}
      end

      context "with embedded nils" do
        let(:tuple) do
          connection.execute("INSERT INTO test (days) VALUES (?) RETURNING *", [4, nil]).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, days: [4, nil]}
        end
      end
    end

    context "against an numeric[] field" do
      let(:table) { "CREATE TABLE test (id serial primary key, prices numeric[])" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (prices) VALUES (?) RETURNING *",
          [BigDecimal("17.45"), BigDecimal("23.72")]).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, prices: [BigDecimal("17.45"), BigDecimal("23.72")]}
      end
    end

    context "against an boolean[] field" do
      let(:table) { "CREATE TABLE test (id serial primary key, truths boolean[])" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (truths) VALUES (?) RETURNING *",
          [false, true]
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, truths: [false, true]}
      end

      context "with embedded nils" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (truths) VALUES (?) RETURNING *",
            [false, nil]
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, truths: [false, nil]}
        end
      end
    end

    context "against an bytea[] field" do
      let(:table) { "CREATE TABLE test (id serial primary key, salts bytea[])" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (salts) VALUES (?) RETURNING *",
          ["\x00\x11", "\x22\x33"]
        ).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, salts: ["\x00\x11", "\x22\x33"]}
      end

      context "with embedded nils" do
        let(:tuple) do
          connection.execute(
            "INSERT INTO test (salts) VALUES (?) RETURNING *",
            ["\x00\x11", nil]
          ).first
        end

        it "is inferred correctly" do
          tuple.should == {id: 1, salts: ["\x00\x11", nil]}
        end
      end
    end

    context "against an date[] field" do
      let(:table) { "CREATE TABLE test (id serial primary key, days date[])" }
      let(:tuple) do
        connection.execute(
          "INSERT INTO test (days) VALUES (?) RETURNING *",
          [Date.new(2012, 9, 22), Date.new(1983, 5, 3)]).first
      end

      it "is inferred correctly" do
        tuple.should == {id: 1, days: [Date.new(2012, 9, 22), Date.new(1983, 5, 3)]}
      end
    end
  end

  describe "arbitrary Object param" do
    context "against a text field" do
      let(:value) { Object.new }
      let(:table) { "CREATE TABLE test (id serial primary key, name text)" }
      let(:tuple) do
        connection.execute("INSERT INTO test (name) VALUES (?) RETURNING *", value).first
      end

      it "is inferred correctly (via #to_s)" do
        tuple.should == {id: 1, name: value.to_s}
      end
    end
  end

  describe "multiple params" do
    let(:table) do
      <<-SQL
      CREATE TABLE test (
        id         serial primary key,
        name       text,
        age        integer,
        admin      boolean,
        created_at timestamptz
      )
      SQL
    end

    let(:tuple) do
      connection.execute(<<-SQL, "bob", 17, false, Time.new(2012, 9, 22, 6, 34, 0, "-07:00")).first
      INSERT INTO test (
        name, age, admin, created_at
      ) VALUES (
        ?, ?, ?, ?
      ) RETURNING *
      SQL
    end

    it "interprets them individually" do
      tuple.should == {
        id:         1,
        name:       "bob",
        age:        17,
        admin:      false,
        created_at: DateTime.new(2012, 9, 22, 6, 34, 0, "-07:00")
      }
    end
  end

  describe "bind markers in a string literals" do
    let(:table) do
      <<-SQL
      CREATE TABLE test (
        id   serial primary key,
        name text,
        age  integer
      )
      SQL
    end

    context "without quoted apostrophes" do
      let(:tuple) do
        connection.execute(<<-SQL, 17).first
        INSERT INTO test (
          name, age
        ) VALUES (
          '?', ?
        ) RETURNING *
        SQL
      end

      it "does not consider the quoted marker" do
        tuple.should == {id: 1, name: "?", age: 17}
      end
    end

    context "with quoted apostrophes" do
      let(:tuple) do
        connection.execute(<<-SQL, 17).first
        INSERT INTO test (
          name, age
        ) VALUES (
          'you say ''hello?''', ?
        ) RETURNING *
        SQL
      end

      it "does not consider the quoted marker" do
        tuple.should == {id: 1, name: "you say 'hello?'", age: 17}
      end
    end
  end

  describe "when a bind marker is contained in a multi-line comment" do
    let(:table) do
      <<-SQL
      CREATE TABLE test (
        id   serial primary key,
        name text,
        age  integer
      )
      SQL
    end

    context "without nesting" do
      let(:tuple) do
        connection.execute(<<-SQL, "jim", 17).first
        INSERT INTO test (
          name, age
        ) VALUES (
          /*
          Are these are the values you're looking for?
          */
          ?, ?
        ) RETURNING *
        SQL
      end

      it "does not consider the commented marker" do
        tuple.should == {id: 1, name: "jim", age: 17}
      end
    end

    context "with nesting" do
      let(:tuple) do
        connection.execute(<<-SQL, "jim", 17).first
        INSERT INTO test (
          name, age
        ) VALUES (
          /*
          Are these the /* nested */ values you're looking for?
          */
          ?, ?
        ) RETURNING *
        SQL
      end

      it "does not consider the commented marker" do
        tuple.should == {id: 1, name: "jim", age: 17}
      end
    end
  end

  context "when a bind marker is contained in a single line comment" do
    let(:table) do
      <<-SQL
      CREATE TABLE test (
        id   serial primary key,
        name text,
        age  integer
      )
      SQL
    end

    let(:tuple) do
      connection.execute(<<-SQL, "jim", 17).first
      INSERT INTO test (
        name, age
      ) VALUES (
        -- Are these are the values you're looking for? choker! /*
        ?, ?
      ) RETURNING *
      SQL
    end

    it "does not consider the commented marker" do
      tuple.should == {id: 1, name: "jim", age: 17}
    end
  end

  context "when a bind parameter is quoted as an identifier" do
    let(:table) do
      <<-SQL
      CREATE TABLE test (
        id       serial primary key,
        name     text,
        age      integer,
        "admin?" boolean
      )
      SQL
    end

    let(:tuple) do
      connection.execute(<<-SQL, "jim", 17, true).first
      INSERT INTO test (
        name, age, "admin?"
      ) VALUES (
        ?, ?, ?
      ) RETURNING *
      SQL
    end

    it "does not confuse the quoted identifier" do
      tuple.should == {id: 1, name: "jim", age: 17, admin?: true}
    end
  end
end
