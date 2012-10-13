require "spec_helper"
require "rational"

describe RDO::Postgres::Driver, "type casting" do
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

    context "using smallint" do
      let(:sql) { "SELECT 42::smallint" }

      it "returns a Fixnum" do
        value.should == 42
      end
    end

    context "using bigint" do
      let(:sql) { "SELECT 42::bigint" }

      it "returns a Fixnum" do
        value.should == 42
      end
    end
  end

  describe "text cast" do
    let(:sql) { "SELECT 42::text" }

    it "returns a String" do
      value.should == "42"
    end
  end

  describe "varchar cast" do
    let(:sql) { "SELECT 'a very long string'::varchar(10)" }

    it "returns a String" do
      value.should == "a very lon"
    end
  end

  describe "char cast" do
    let(:sql) { "SELECT 'a very long string'::char(10)" }

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

  describe "bytea cast" do
    let(:sql) { "SELECT decode('00112233', 'hex')::bytea" }

    context "using bytea_output = hex" do
      before(:each) { connection.execute("SET bytea_output = hex") }

      it "returns a String" do
        value.should == "\x00\x11\x22\x33"
      end
    end

    context "using bytea_output = escape" do
      before(:each) do
        # don't error on older versions of postgresql
        connection.execute("SET bytea_output = escape") rescue nil
      end

      it "returns a String" do
        value.should == "\x00\x11\x22\x33"
      end
    end
  end

  describe "float cast" do
    let(:sql) { "SELECT 1.2::float" }

    it "returns a Float" do
      value.should be_a_kind_of(Float)
      value.should <= 1.201
      value.should >= 1.199
    end

    context "using real" do
      let(:sql) { "SELECT 1.2::real" }

      it "returns a Float" do
        value.should be_a_kind_of(Float)
        value.should <= 1.201
        value.should >= 1.199
      end
    end

    context "using double precision" do
      let(:sql) { "SELECT 1.2::double precision" }

      it "returns a Float" do
        value.should be_a_kind_of(Float)
        value.should <= 1.201
        value.should >= 1.199
      end
    end

    context "for 'NaN'" do
      let(:sql) { "SELECT 'NaN'::float" }

      it "returns Float::NAN" do
        value.should be_a_kind_of(Float)
        value.should be_nan
      end
    end

    context "for 'Infinity'" do
      let(:sql) { "SELECT 'Infinity'::float" }

      it "returns Float::INFINITY" do
        value.should  == Float::INFINITY
      end
    end

    context "for '-Infinity'" do
      let(:sql) { "SELECT '-Infinity'::float" }

      it "returns -Float::INFINITY" do
        value.should  == -Float::INFINITY
      end
    end

    context "for '1E-06'" do
      let(:sql) { "SELECT '1E-06'::float" }

      it "returns 1e-06" do
        value.should be_a_kind_of(Float)
        value.should >= Float("1E-06") - 0.01
        value.should <= Float("1E-06") + 0.01
      end
    end
  end

  describe "decimal cast" do
    require "bigdecimal"

    %w[decimal numeric].each do |type|
      context "as #{type}" do
        context "using a max precision and scale" do
          let(:sql) { "SELECT '124.36'::#{type}(5,2)" }

          it "returns a BigDecimal" do
            value.should == BigDecimal("124.36")
          end
        end

        context "using a max precision only" do
          let(:sql) { "SELECT '124.36'::#{type}(5)" }

          it "returns a BigDecimal" do
            value.should == BigDecimal("124")
          end
        end

        context "using no precision or scale" do
          let(:sql) { "SELECT '124.36'::#{type}" }

          it "returns a BigDecimal" do
            value.should == BigDecimal("124.36")
          end
        end

        context "for 'NaN'" do
          let(:sql) { "SELECT 'NaN'::#{type}" }

          it "returns a BigDecimal" do
            value.should be_a_kind_of(BigDecimal)
            value.should be_nan
          end
        end
      end
    end
  end

  describe "date cast" do
    context "with YYYY-MM-DD format date" do
      let(:sql) { "SELECT '2012-09-22'::date" }

      it "returns a Date" do
        value.should == Date.new(2012, 9, 22)
      end
    end

    context "with YYY-MM-DD AD format date" do
      let(:sql) { "SELECT '432-09-22 AD'::date" }

      it "returns a Date" do
        value.should == Date.new(432, 9, 22)
      end
    end

    context "with YYY-MM-DD BC format date" do
      let(:sql) { "SELECT '432-09-22 BC'::date" }

      it "returns a Date" do
        value.should == Date.new(-431, 9, 22)
      end
    end
  end

  describe "timestamp cast" do
    context "without a time zone" do
      let(:sql) { "SELECT '2012-09-22 04:26:34'::timestamp" }

      it "returns a DateTime in the local time zone" do
        value.should == DateTime.new(2012, 9, 22, 4, 26, 34, DateTime.now.zone)
      end
    end

    context "with a time zone" do
      let(:sql) { "SELECT '2012-09-22 04:26:34'::timestamptz" }

      it "returns a DateTime, in the system time zone" do
        value.should == DateTime.new(2012, 9, 22, 4, 26, 34, DateTime.now.zone)
      end

      context "specifying an alternate time zone" do
        let(:sql) { "SELECT '2012-09-22 04:26:34'::timestamp at time zone 'UTC'" }

        it "returns a DateTime at the system time zone" do
          value.should == DateTime.new(2012, 9, 22, 4, 26, 34, 0).new_offset(Time.now.utc_offset)
        end
      end

      context "with a different time zone set on the connection" do
        before(:each) { connection.execute("SET timezone = 'UTC'") }

        it "returns a DateTime with the conversion done accordingly" do
          value.should == DateTime.new(2012, 9, 22, 4, 26, 34, 0)
        end
      end
    end
  end

  describe "text[] cast" do
    let(:sql) { "SELECT ARRAY['a', 'b']::text[]" }

    it "returns an Array of Strings" do
      value.should == ["a", "b"]
    end

    context "including quotes" do
      let(:sql) { %q{SELECT ARRAY['a "b"', '"c" d']::text[]} }

      it "returns an Array of Strings" do
        value.should == ['a "b"', '"c" d']
      end
    end

    context "including backslashes" do
      let(:sql) { %q{SELECT ARRAY['a \\b', '\\c d']::text[]} }

      it "returns an Array of Strings" do
        value.should == ['a \\b', '\\c d']
      end
    end

    context "including NULLs" do
      let(:sql) { "SELECT ARRAY[NULL, 'b']::text[]" }

      it "returns an Array including nil" do
        value.should == [nil, "b"]
      end
    end
  end
end
