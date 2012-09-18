require "spec_helper"

describe RDO::Postgres::Connection do
  describe "#initialize" do
    let(:options)    { Hash[] }
    let(:connection) { RDO.connect(options) }

    context "with valid settings" do
      let(:options) { "postgresql://flippa:flippa@192.168.27.1/flippa" }

      it "opens a connection to the server" do
        connection.should be_open
      end
    end

    context "with invalid settings" do
      let(:options) { "postgresql://baduser:badpass@localhost/bad_dbname" }

      it "raises a RDO::Exception" do
        expect { connection }.to raise_error(RDO::Exception)
      end
    end
  end
end
