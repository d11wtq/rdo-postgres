require "spec_helper"

describe RDO::Postgres::Array::Date do
  it "is a kind of ::Array" do
    RDO::Postgres::Array::Date.new.should be_a_kind_of(::Array)
  end

  describe "#to_s" do
    context "with an empty array" do
      let(:arr) { RDO::Postgres::Array::Date[] }

      it "returns {}" do
        arr.to_s.should == '{}'
      end
    end

    context "with an array of Dates" do
      let(:arr) { RDO::Postgres::Array::Date[Date.new(2012, 9, 22), Date.new(1983, 5, 3)] }

      it "formats the dates in quotes" do
        arr.to_s.should == '{"2012-09-22","1983-05-03"}'
      end
    end

    context "with an array containing nil" do
      let(:arr) { RDO::Postgres::Array::Date[nil, Date.new(1983, 5, 3)] }

      it "uses NULL" do
        arr.to_s.should == '{NULL,"1983-05-03"}'
      end
    end
  end

  describe "#to_a" do
    let(:arr) { RDO::Postgres::Array::Date[Date.new(2012, 9, 22), Date.new(1983, 5, 3)] }

    it "returns a core ruby Array" do
      arr.to_a.class.should == ::Array
    end
  end

  describe ".parse" do
    let(:str) { '{}' }
    let(:arr) { RDO::Postgres::Array::Date.parse(str) }

    it "returns a RDO::Postgres::Array::Date" do
      arr.should be_a_kind_of(RDO::Postgres::Array::Date)
    end

    context "with an empty array string" do
      let(:str) { '{}' }

      it "returns an empty Array" do
        arr.should be_empty
      end
    end

    context "with an array of dates" do
      let(:str) { '{"2012-09-22","1983-05-03"}' }

      it "returns an Array of Dates" do
        arr.to_a.should == [Date.new(2012, 9, 22), Date.new(1983, 5, 3)]
      end
    end

    context "with an array containing NULL" do
      let(:str) { '{NULL,"1983-05-03"}' }

      it "uses nil as the value" do
        arr.to_a.should == [nil, Date.new(1983, 5, 3)]
      end
    end
  end
end
