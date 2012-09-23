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
end
