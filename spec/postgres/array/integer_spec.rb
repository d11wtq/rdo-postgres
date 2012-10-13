require "spec_helper"

describe RDO::Postgres::Array::Integer do
  it "is a kind of ::Array" do
    RDO::Postgres::Array::Integer.new.should be_a_kind_of(::Array)
  end

  describe "#to_s" do
    context "with an empty array" do
      let(:arr) { RDO::Postgres::Array::Integer[] }

      it "returns {}" do
        arr.to_s.should == '{}'
      end
    end

    context "with an array of Fixnums" do
      let(:arr) { RDO::Postgres::Array::Integer[1, 2, 3] }

      it "comma separates the numbers" do
        arr.to_s.should == '{1,2,3}'
      end
    end

    context "with an array containing nil" do
      let(:arr) { RDO::Postgres::Array::Integer[nil, nil, 7] }

      it "uses NULL" do
        arr.to_s.should == '{NULL,NULL,7}'
      end
    end
  end

  describe "#to_a" do
    let(:arr) { RDO::Postgres::Array::Integer[1, 2, 3] }

    it "returns a core ruby Array" do
      arr.to_a.class.should == ::Array
    end
  end

  describe ".parse" do
    let(:str) { '{}' }
    let(:arr) { RDO::Postgres::Array::Integer.parse(str) }

    it "returns a RDO::Postgres::Array::Integer" do
      arr.should be_a_kind_of(RDO::Postgres::Array::Integer)
    end

    context "with an empty array string" do
      let(:str) { '{}' }

      it "returns an empty Array" do
        arr.should be_empty
      end
    end

    context "with an array of integers" do
      let(:str) { '{1,2,3}' }

      it "returns an Array of Fixnums" do
        arr.to_a.should == [1, 2, 3]
      end
    end

    context "with an array containing NULL" do
      let(:str) { '{NULL,NULL,7}' }

      it "uses nil as the value" do
        arr.to_a.should == [nil, nil, 7]
      end
    end
  end
end
