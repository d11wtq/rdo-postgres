require "spec_helper"
require "uri"

describe RDO::Postgres::Driver do
  let(:options)    { connection_uri }
  let(:connection) { RDO.connect(options) }

  after(:each) { connection.close rescue nil }

  describe "#initialize" do
    context "with valid settings" do
      it "opens a connection to the server" do
        connection.should be_open
      end
    end

    context "with invalid settings" do
      let(:options) { URI.parse(connection_uri).tap{|u| u.user = "bad_user"}.to_s }

      it "raises a RDO::Exception" do
        expect { connection }.to raise_error(RDO::Exception)
      end

      it "provides a meaningful error message" do
        begin
          connection && fail("RDO::Exception should be raised")
        rescue RDO::Exception => e
          e.message.should =~ /\bbad_user\b/
        end
      end
    end
  end

  describe "#close" do
    it "closes the connection to the database" do
      connection.close
      connection.should_not be_open
    end

    it "returns true" do
      connection.close.should be_true
    end

    context "called multiple times" do
      it "has no negative side-effects" do
        5.times { connection.close }
        connection.should_not be_open
      end
    end
  end

  describe "#open" do
    it "re-opens the connection to the database" do
      connection.close && connection.open
      connection.should be_open
    end

    it "returns true" do
      connection.close
      connection.open.should be_true
    end

    context "called multiple times" do
      it "has no negative side-effects" do
        connection.close
        5.times { connection.open }
        connection.should be_open
      end
    end
  end

  describe "#execute" do
    after(:each) do
      connection.execute("DROP SCHEMA IF EXISTS rdo_test CASCADE")
    end

    context "with DDL" do
      let(:result) do
        connection.execute("CREATE SCHEMA rdo_test")
      end

      it "returns a RDO::Result" do
        result.should be_a_kind_of(RDO::Result)
      end
    end

    context "with a bad query" do
      let(:command) { connection.execute("SOME GIBBERISH") }

      it "raises a RDO::Exception" do
        expect { command }.to raise_error(RDO::Exception)
      end

      it "provides a meaningful error message" do
        begin
          command && fail("RDO::Exception should be raised")
        rescue RDO::Exception => e
          e.message.should =~ /\bSOME\b/
        end
      end
    end

    context "with an INSERT" do
      before(:each) do
        connection.execute("CREATE SCHEMA rdo_test")
        connection.execute("SET search_path = rdo_test")
        connection.execute(
          "CREATE TABLE users (id serial primary key, name text)"
        )
      end

      context "returning rows" do
        let(:result) do
          connection.execute(
            "INSERT INTO users (name) VALUES ('bob') RETURNING *"
          )
        end

        it "returns a RDO::Result" do
          result.should be_a_kind_of(RDO::Result)
        end

        it "provides the return values" do
          result.first[:id].should == 1
          result.first[:name].should == "bob"
        end

        it "provides the #insert_id" do
          result.insert_id.should == 1
        end

        it "provides the number of #affected_rows" do
          result.affected_rows.should == 1
        end
      end

      context "not returning" do
        let(:result) do
          connection.execute("INSERT INTO users (name) VALUES ('bob')")
        end

        it "returns a RDO::Result" do
          result.should be_a_kind_of(RDO::Result)
        end

        it "has a nil #insert_id" do
          result.insert_id.should be_nil
        end

        it "provides the number of #affected_rows" do
          result.affected_rows.should == 1
        end
      end

      context "using bind parameters" do
        let(:result) do
          connection.execute("INSERT INTO users (name) VALUES (?)", "bob")
        end

        it "returns a RDO::Result" do
          result.should be_a_kind_of(RDO::Result)
        end

        it "provides the number of #affected_rows" do
          result.affected_rows.should == 1
        end
      end
    end

    context "with a SELECT" do
      before(:each) do
        connection.execute("CREATE SCHEMA rdo_test")
        connection.execute("SET search_path = rdo_test")
      end

      context "returning no rows" do
        let(:result) { connection.execute("SELECT unnest('{}'::text[])") }

        it "returns a RDO::Result" do
          result.should be_a_kind_of(RDO::Result)
        end

        it "has no tuples" do
          result.count.should == 0
        end

        it "can be converted to an empty array" do
          result.to_a.should == []
        end
      end

      context "returning rows" do
        before(:each) do
          connection.execute(
            "CREATE TABLE users (id serial primary key, name text)"
          )
          connection.execute("INSERT INTO users (name) VALUES ('bob'), ('barry')")
        end

        let(:result) { connection.execute("SELECT * FROM users") }

        it "returns a RDO::Result" do
          result.should be_a_kind_of(RDO::Result)
        end

        it "provides the row count" do
          result.count.should == 2
        end

        it "allows enumeration of the rows" do
          rows = []
          result.each{|row| rows << row }
          rows.should == [{id: 1, name: "bob"}, {id: 2, name: "barry"}]
        end

        context "using bind parameters" do
          let(:result) do
            connection.execute("SELECT * FROM users WHERE name = ?", "barry")
          end

          it "returns a RDO::Result" do
            result.should be_a_kind_of(RDO::Result)
          end

          it "provides the correct count" do
            result.count.should == 1
          end

          it "allows enumeration of the rows" do
            rows = []
            result.each{|row| rows << row}
            rows.should == [{id: 2, name: "barry"}]
          end
        end
      end
    end
  end

  describe "string encoding" do
    context "with utf-8" do
      let(:options) { URI.parse(connection_uri).tap{|u| u.query = "encoding=utf-8"}.to_s }

      it "returns utf-8 strings" do
        connection.execute("SELECT 'foo'::text").first_value.encoding.should ==
          Encoding.find("utf-8")
      end
    end

    context "with iso-8859-1" do
      let(:options) { URI.parse(connection_uri).tap{|u| u.query = "encoding=iso-8859-1"}.to_s }

      it "returns iso-8859-1 strings" do
        connection.execute("SELECT 'foo'::text").first_value.encoding.should ==
          Encoding.find("iso-8859-1")
      end
    end

    context "with latin1" do
      let(:options) { URI.parse(connection_uri).tap{|u| u.query = "encoding=latin1"}.to_s }

      it "returns ascii-8bit strings (ruby doesn't know this charset)" do
        connection.execute("SELECT 'foo'::text").first_value.encoding.should ==
          Encoding.find("binary")
      end
    end
  end

  describe "#quote" do
    it "quotes a string literal for insertion into the SQL" do
      connection.quote("what's this?").should == "what''s this?"
    end
  end

  describe "#prepare" do
    it "returns a RDO::Statement" do
      connection.prepare("SELECT ?::text").should be_a_kind_of(RDO::Statement)
    end

    it "can be executed multiple times" do
      stmt = connection.prepare("SELECT ?::integer + ?")
      stmt.execute(4, 7).first_value.should == 11
      stmt.execute(5, 22).first_value.should == 27
    end
  end
end
