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

    context "using int2" do
      let(:sql) { "SELECT 42::int2" }

      it "returns a Fixnum" do
        value.should == 42
      end
    end

    context "using int4" do
      let(:sql) { "SELECT 42::int4" }

      it "returns a Fixnum" do
        value.should == 42
      end
    end

    context "using int8" do
      let(:sql) { "SELECT 42::int8" }

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

    context "using float4" do
      let(:sql) { "SELECT 1.2::float4" }

      it "returns a Float" do
        value.should be_a_kind_of(Float)
        value.should <= 1.201
        value.should >= 1.199
      end
    end

    context "using float8" do
      let(:sql) { "SELECT 1.2::float8" }

      it "returns a Float" do
        value.should be_a_kind_of(Float)
        value.should <= 1.201
        value.should >= 1.199
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
end
