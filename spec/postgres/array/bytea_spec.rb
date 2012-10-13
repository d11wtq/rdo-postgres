require "spec_helper"

describe RDO::Postgres::Array::Bytea do
  it "is a kind of ::Array" do
    RDO::Postgres::Array::Bytea.new.should be_a_kind_of(::Array)
  end

  describe "#to_s" do
    context "with an empty array" do
      let(:arr) { RDO::Postgres::Array::Bytea[] }

      it "returns {}" do
        arr.to_s.should == '{}'
      end
    end

    context "with an array of Strings" do
      let(:arr) { RDO::Postgres::Array::Bytea["\x00\x11", "\x22\x33", "\x44\x55"] }

      it "escapes the binary data" do
        if arr.to_s =~ /\\x/
          arr.to_s.should == '{"\\x00\\x11","\\x22\\x33","\\x44\\x55"}'
        else
          arr.to_s.should == '{"\\\\000\\\\021","\\"3","DU"}'
        end
      end

      context "containing nil" do
        let(:arr) { RDO::Postgres::Array::Bytea["\x00\x11", nil] }

        it "uses NULL" do
          if arr.to_s =~ /\\x/
            arr.to_s.should == '{"\\x00\\x11",NULL}'
          else
            arr.to_s.should == '{"\\\\000\\\\021",NULL}'
          end
        end
      end
    end
  end

  describe "#to_a" do
    let(:arr) { RDO::Postgres::Array::Bytea["\x00\x11", "\x22\x33", "\x44\x55"] }

    it "returns a Ruby ::Array" do
      arr.to_a.should == ["\x00\x11", "\x22\x33", "\x44\x55"]
    end
  end

  describe ".parse" do
    let(:str) { '{}' }
    let(:arr) { RDO::Postgres::Array::Bytea.parse(str) }

    it "returns a RDO::Postgres::Array::Bytea" do
      arr.should be_a_kind_of(RDO::Postgres::Array::Bytea)
    end

    context "with an empty array string" do
      let(:str) { '{}' }

      it "returns an empty Array" do
        arr.should be_empty
      end
    end

    context "with an array of byteas" do
      let(:str) { '{"\\\\x0011","\\\\x2233"}' }

      it "returns an Array of Strings" do
        arr.to_a.should == ["\x00\x11", "\x22\x33"]
      end
    end

    context "with an array containing NULL" do
      let(:str) { '{NULL,NULL,"\\\\x0011"}' }

      it "uses nil as the value" do
        arr.to_a.should == [nil, nil, "\x00\x11"]
      end
    end
  end
end
