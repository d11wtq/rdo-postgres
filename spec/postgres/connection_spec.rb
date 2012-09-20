require "spec_helper"
require "uri"

describe RDO::Postgres::Connection do
  let(:options)    { connection_uri }
  let(:connection) { RDO.connect(options) }

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

      context "RETURNING" do
        let(:result) do
          connection.execute(
            "INSERT INTO users (name) VALUES ('bob') RETURNING *"
          )
        end

        it "returns a RDO::Result" do
          result.should be_a_kind_of(RDO::Result)
        end

        it "provides the return values" do
          result.first[:id].to_i.should == 1
          result.first[:name].to_s.should == "bob"
        end

        it "provides the insert_id" do
          result.insert_id.to_i.should == 1
        end
      end
    end
  end
end
