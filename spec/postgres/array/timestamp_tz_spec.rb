require "spec_helper"

describe RDO::Postgres::Array::TimestampTZ do
  it "is a kind of ::Array" do
    RDO::Postgres::Array::TimestampTZ.new.should be_a_kind_of(::Array)
  end

  describe "#to_s" do
    context "with an empty array" do
      let(:arr) { RDO::Postgres::Array::TimestampTZ[] }

      it "returns {}" do
        arr.to_s.should == '{}'
      end
    end

    context "with an array of DateTimes" do
      let(:arr) { RDO::Postgres::Array::TimestampTZ[
        DateTime.new(2012, 9, 22, 5, 43, 2, "-07:00"),
        DateTime.new(1983, 5, 3, 15, 0, 1, "+10:00")
      ] }

      it "formats the times in quotes" do
        arr.to_s.should == %Q[{"#{DateTime.new(2012, 9, 22, 5, 43, 2, "-07:00")}","#{DateTime.new(1983, 5, 3, 15, 0, 1, "+10:00")}"}]
      end
    end

    context "with an array containing nil" do
      let(:arr) { RDO::Postgres::Array::TimestampTZ[nil, DateTime.new(1983, 5, 3, 0, 0, 1, "-07:00")] }

      it "uses NULL" do
        arr.to_s.should == %Q[{NULL,"#{DateTime.new(1983, 5, 3, 0, 0, 1, "-07:00")}"}]
      end
    end
  end

  describe "#to_a" do
    let(:arr) { RDO::Postgres::Array::TimestampTZ[DateTime.new(2012, 9, 22, 0, 0, 0, "-07:00")] }

    it "returns a core ruby Array" do
      arr.to_a.class.should == ::Array
    end
  end

  describe ".parse" do
    let(:str) { '{}' }
    let(:arr) { RDO::Postgres::Array::TimestampTZ.parse(str) }

    it "returns a RDO::Postgres::Array::TimestampTZ" do
      arr.should be_a_kind_of(RDO::Postgres::Array::TimestampTZ)
    end

    context "with an empty array string" do
      let(:str) { '{}' }

      it "returns an empty Array" do
        arr.should be_empty
      end
    end

    context "with an array of timestamps" do
      let(:str) { '{"2012-09-22 05:34:01 -07:00","1983-05-03 13:59:09 +10:00"}' }

      it "returns an Array of DateTimes" do
        arr.to_a.should == [
          DateTime.new(2012, 9, 22, 5, 34, 1, "-07:00"),
          DateTime.new(1983, 5, 3, 13, 59, 9, "+10:00")
        ]
      end
    end

    context "with an array containing NULL" do
      let(:str) { '{NULL,"1983-05-03 00:04:05 -07:00"}' }

      it "uses nil as the value" do
        arr.to_a.should == [nil, DateTime.new(1983, 5, 3, 0, 4, 5, "-07:00")]
      end
    end
  end
end
