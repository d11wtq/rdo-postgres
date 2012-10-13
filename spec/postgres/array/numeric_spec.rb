require "spec_helper"

describe RDO::Postgres::Array::Numeric do
  it "is a kind of ::Array" do
    RDO::Postgres::Array::Numeric.new.should be_a_kind_of(::Array)
  end

  describe "#to_s" do
    context "with an empty array" do
      let(:arr) { RDO::Postgres::Array::Numeric[] }

      it "returns {}" do
        arr.to_s.should == '{}'
      end
    end

    context "with an array of BigDecimals" do
      let(:arr) { RDO::Postgres::Array::Numeric[BigDecimal("1.2"), BigDecimal("2.4")] }

      it "comma separates the numbers" do
        arr.to_s.should == "{#{BigDecimal('1.2').to_s},#{BigDecimal('2.4').to_s}}"
      end
    end

    context "with an array containing nil" do
      let(:arr) { RDO::Postgres::Array::Numeric[nil, BigDecimal("7.2")] }

      it "uses NULL" do
        arr.to_s.should == "{NULL,#{BigDecimal('7.2').to_s}}"
      end
    end
  end

  describe "#to_a" do
    let(:arr) { RDO::Postgres::Array::Numeric[BigDecimal("1.2"), BigDecimal("2.4")] }

    it "returns a core ruby Array" do
      arr.to_a.class.should == ::Array
    end
  end

  describe ".parse" do
    let(:str) { '{}' }
    let(:arr) { RDO::Postgres::Array::Numeric.parse(str) }

    it "returns a RDO::Postgres::Array::Numeric" do
      arr.should be_a_kind_of(RDO::Postgres::Array::Numeric)
    end

    context "with an empty array string" do
      let(:str) { '{}' }

      it "returns an empty Array" do
        arr.should be_empty
      end
    end

    context "with an array of decimals" do
      let(:str) { '{1.2,2.4}' }

      it "returns an Array of BigDecimals" do
        arr.to_a.should == [BigDecimal("1.2"), BigDecimal("2.4")]
      end
    end

    context "with an array containing NULL" do
      let(:str) { '{NULL,7.2}' }

      it "uses nil as the value" do
        arr.to_a.should == [nil, BigDecimal("7.2")]
      end
    end

    context "with an array containing NaN" do
      let(:str) { '{NaN,7.2}' }

      it "uses BigDecimal('NaN') as the value" do
        arr.to_a[0].should be_nan
        arr.to_a[1].should == BigDecimal("7.2")
      end
    end
  end
end
