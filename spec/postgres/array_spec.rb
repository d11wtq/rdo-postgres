require "spec_helper"

describe RDO::Postgres::Array do
  it "is a kind of ::Array" do
    RDO::Postgres::Array.new.should be_a_kind_of(::Array)
  end

  describe "#to_s" do
    context "with an empty array" do
      let(:arr) { RDO::Postgres::Array[] }

      it "returns {}" do
        arr.to_s.should == '{}'
      end
    end

    context "with an array of Strings" do
      let(:arr) { RDO::Postgres::Array["a", "b", "c"] }

      it "wraps double quotes around the elements" do
        arr.to_s.should == '{"a","b","c"}'
      end

      context "containing double quotes" do
        let(:arr) { RDO::Postgres::Array["a", "b and \"c\""] }

        it "escapes the quotes" do
          arr.to_s.should == '{"a","b and \\"c\\""}'
        end
      end

      context "containing backslashes" do
        let(:arr) { RDO::Postgres::Array["a", "b and \\c"] }

        it "escapes the backslashes" do
          arr.to_s.should == '{"a","b and \\\\c"}'
        end
      end
    end

    context "with an array containing nil" do
      let(:arr) { RDO::Postgres::Array[nil, nil, "c"] }

      it "uses NULL" do
        arr.to_s.should == '{NULL,NULL,"c"}'
      end
    end

    context "with an array containing non-Strings" do
      let(:arr) { RDO::Postgres::Array[42, 7] }

      it "converts the objects to Strings" do
        arr.to_s.should == '{"42","7"}'
      end
    end

    context "with a multi-dimensional Array" do
      let(:arr) { RDO::Postgres::Array[["a", "b"], ["c", "d"]] }

      it "formats the inner Arrays" do
        arr.to_s.should == '{{"a","b"},{"c","d"}}'
      end
    end
  end

  describe "#to_a" do
    let(:arr) { RDO::Postgres::Array[1, 2, 3] }

    it "returns a core ruby Array" do
      arr.to_a.class.should == ::Array
    end

    context "with a multidimensional Array" do
      let(:arr) { RDO::Postgres::Array[[1, 2], [3, 4]] }

      it "converts the inner elements to core Ruby Arrays" do
        arr.to_a[0].class.should == ::Array
      end
    end
  end

  describe ".parse" do
    let(:str) { '{}' }
    let(:arr) { RDO::Postgres::Array.parse(str) }

    it "returns a RDO::Postgres::Array" do
      arr.should be_a_kind_of(RDO::Postgres::Array)
    end

    context "with an empty array string" do
      let(:str) { '{}' }

      it "returns an empty Array" do
        arr.should be_empty
      end
    end

    context "with an array of unquoted strings" do
      let(:str) { '{a,b,c}' }

      it "returns an Array of Strings" do
        arr.to_a.should == ["a", "b", "c"]
      end
    end

    context "with an array of quoted strings" do
      let(:str) { '{"a b","c d","e f"}' }

      it "returns an Array of Strings" do
        arr.to_a.should == ["a b", "c d", "e f"]
      end

      context "containing double quotes" do
        let(:str) { '{"a \\"b\\"","\\"c\\" d"}' }

        it "returns an Array of Strings" do
          arr.to_a.should == ['a "b"', '"c" d']
        end
      end

      context "containing backslashes" do
        let(:str) { '{"a \\\\b","\\\\c d"}' }

        it "returns an Array of Strings" do
          arr.to_a.should == ["a \\b", "\\c d"]
        end
      end
    end

    context "with an array containing NULL" do
      let(:str) { '{NULL,NULL,"c"}' }

      it "uses nil as the value" do
        arr.to_a.should == [nil, nil, "c"]
      end
    end

    context "with a multi-dimensonal array" do
      let(:str) { '{{a,b},{c,d}}' }

      it "returns an Array of Arrays of Strings" do
        arr.to_a.should == [["a", "b"], ["c", "d"]]
      end

      context "containing commas" do
        let(:str) { '{{"a,b","c,d"},{"e,f","g,h"}}' }

        it "returns an Array of Arrays of Strings" do
          arr.to_a.should == [["a,b", "c,d"], ["e,f", "g,h"]]
        end
      end

      context "containing escaped quotes" do
        let(:str) { '{{"a \\"b\\"","c \\"d\\""},{"e","f"}}' }

        it "returns an Array of Arrays of Strings" do
          arr.to_a.should == [['a "b"', 'c "d"'], ["e", "f"]]
        end
      end
    end
  end
end
