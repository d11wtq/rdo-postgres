require "spec_helper"

describe RDO::Postgres::Connection, "type casting" do
  let(:options)    { connection_uri }
  let(:connection) { RDO.connect(options) }
  let(:value)      { connection.execute(sql).first_value }

  after(:each) { connection.close rescue nil }

  describe "null cast" do
    let(:sql) { "SELECT null" }

    it "returns nil" do
      value.should be_nil
    end
  end

  describe "integer cast" do
    let(:sql) { "SELECT 42::integer" }

    it "returns a Fixnum" do
      value.should == 42
    end
  end

  describe "text cast" do
    let(:sql) { "SELECT 42::text" }

    it "returns a String" do
      value.should == "42"
    end
  end

  describe "varchar(10) cast" do
    let(:sql) { "SELECT 'a very long string'::varchar(10)" }

    it "returns a String" do
      value.should == "a very lon"
    end
  end

  describe "boolean cast" do
    describe "true" do
      let(:sql) { "SELECT true" }

      it "returns true" do
        value.should == true
      end
    end

    describe "false" do
      let(:sql) { "SELECT false" }

      it "returns false" do
        value.should == false
      end
    end
  end
end
