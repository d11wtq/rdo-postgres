require "spec_helper"

describe RDO::Postgres::Array::Timestamp do
  it "is a kind of ::Array" do
    RDO::Postgres::Array::Timestamp.new.should be_a_kind_of(::Array)
  end

  describe "#to_s" do
    context "with an empty array" do
      let(:arr) { RDO::Postgres::Array::Timestamp[] }

      it "returns {}" do
        arr.to_s.should == '{}'
      end
    end

    context "with an array of Times" do
      let(:arr) { RDO::Postgres::Array::Timestamp[
        Time.new(2012, 9, 22, 5, 43, 2),
        Time.new(1983, 5, 3, 15, 0, 1)
      ] }

      it "formats the times in quotes" do
        arr.to_s.should == %Q[{"#{Time.new(2012, 9, 22, 5, 43, 2)}","#{Time.new(1983, 5, 3, 15, 0, 1)}"}]
      end
    end

    context "with an array containing nil" do
      let(:arr) { RDO::Postgres::Array::Timestamp[nil, Time.new(1983, 5, 3, 0, 0, 1)] }

      it "uses NULL" do
        arr.to_s.should == %Q[{NULL,"#{Time.new(1983, 5, 3, 0, 0, 1)}"}]
      end
    end
  end

  describe "#to_a" do
    let(:arr) { RDO::Postgres::Array::Timestamp[Time.new(2012, 9, 22, 0, 0, 0)] }

    it "returns a core ruby Array" do
      arr.to_a.class.should == ::Array
    end
  end

  describe ".parse" do
    let(:str) { '{}' }
    let(:arr) { RDO::Postgres::Array::Timestamp.parse(str) }

    it "returns a RDO::Postgres::Array::Timestamp" do
      arr.should be_a_kind_of(RDO::Postgres::Array::Timestamp)
    end

    context "with an empty array string" do
      let(:str) { '{}' }

      it "returns an empty Array" do
        arr.should be_empty
      end
    end

    context "with an array of timestamps" do
      let(:str) { '{"2012-09-22 05:34:01","1983-05-03 13:59:09"}' }

      it "returns an Array of DateTimes" do
        arr.to_a.should == [
          DateTime.new(2012, 9, 22, 5, 34, 1, DateTime.now.zone),
          DateTime.new(1983, 5, 3, 13, 59, 9, DateTime.now.zone)
        ]
      end
    end

    context "with an array containing NULL" do
      let(:str) { '{NULL,"1983-05-03 00:04:05"}' }

      it "uses nil as the value" do
        arr.to_a.should == [nil, DateTime.new(1983, 5, 3, 0, 4, 5, DateTime.now.zone)]
      end
    end
  end
end
