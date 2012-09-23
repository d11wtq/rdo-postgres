require "spec_helper"
require "bigdecimal"
require "date"

describe RDO::Postgres::Connection, "bind parameter support" do
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

  describe "text param" do
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
  end
end
