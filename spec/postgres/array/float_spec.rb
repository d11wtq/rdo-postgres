require "spec_helper"

describe RDO::Postgres::Array::Float do
  it "is a kind of ::Array" do
    RDO::Postgres::Array::Float.new.should be_a_kind_of(::Array)
  end

  describe "#to_s" do
    context "with an empty array" do
      let(:arr) { RDO::Postgres::Array::Float[] }

      it "returns {}" do
        arr.to_s.should == '{}'
      end
    end

    context "with an array of Floats" do
      let(:arr) { RDO::Postgres::Array::Float[1.2, 2.4, 3.6] }

      it "comma separates the numbers" do
        arr.to_s.should == '{1.2,2.4,3.6}'
      end
    end

    context "with an array containing nil" do
      let(:arr) { RDO::Postgres::Array::Float[nil, nil, 7.2] }

      it "uses NULL" do
        arr.to_s.should == '{NULL,NULL,7.2}'
      end
    end
  end

  describe "#to_a" do
    let(:arr) { RDO::Postgres::Array::Float[1.2, 2.4, 3.6] }

    it "returns a core ruby Array" do
      arr.to_a.class.should == ::Array
    end
  end

  describe ".parse" do
    let(:str) { '{}' }
    let(:arr) { RDO::Postgres::Array::Float.parse(str) }

    it "returns a RDO::Postgres::Array::Float" do
      arr.should be_a_kind_of(RDO::Postgres::Array::Float)
    end

    context "with an empty array string" do
      let(:str) { '{}' }

      it "returns an empty Array" do
        arr.should be_empty
      end
    end

    context "with an array of floats" do
      let(:str) { '{1.2,2.4,3.6}' }

      it "returns an Array of Floats" do
        arr.to_a.should == [1.2, 2.4, 3.6]
      end
    end

    context "with an array containing NULL" do
      let(:str) { '{NULL,NULL,7.2}' }

      it "uses nil as the value" do
        arr.to_a.should == [nil, nil, 7.2]
      end
    end

    context "with an array containing NaN" do
      let(:str) { '{NaN,7.2}' }

      it "uses Float::NAN as the value" do
        arr.to_a.should == [Float::NAN, 7.2]
      end
    end

    context "with an array containing Infinity" do
      let(:str) { '{Infinity,7.2}' }

      it "uses Float::INFINITY as the value" do
        arr.to_a.should == [Float::INFINITY, 7.2]
      end
    end

    context "with an array containing -Infinity" do
      let(:str) { '{-Infinity,7.2}' }

      it "uses -Float::INFINITY as the value" do
        arr.to_a.should == [-Float::INFINITY, 7.2]
      end
    end
  end
end
