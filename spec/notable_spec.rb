require "#{File.dirname(__FILE__)}/spec_helper"

describe "Notable" do
  before(:each) do
    @klass = Notable
    @filename = 'notes.yml'
    @username = 'a@b.c'
    @password = 'seekrit'
    @resource = 'note_test'
    @database_hash = {'adapter' => 'sqlite3', 'database' => ':memory:'}
    @config_hash = { 
                    'database' => @database_hash
                 }
    YAML.stub!(:load_file).and_return(@config_hash)
    @conf = Notable::Configuration.new(@filename)
    Notable::Configuration.stub!(:new).and_return(@conf) 
  end


  describe "#setup" do
    it "responds to #setup" do
      @klass.should respond_to(:setup)
    end

    it "creates a new configuration with the filename" do
      Notable::Configuration.should_receive(:new).with(@filename).and_return(@conf)
      @klass.setup(@filename)
    end
  end


  describe "#connect" do
    before(:each) do
      # we don't actually want to connect!
      DataMapper.stub!(:setup)
      @klass.setup(@filename)
    end

    it "responds to #connect" do
      @klass.should respond_to(:connect)
    end

    it "sets up the DataMapper connection" do
      DataMapper.should_receive(:setup).with(:default, @database_hash)
      @klass.connect
    end
  end


  describe "#configuration" do
    it "responds to #configuration" do
      @klass.should respond_to(:configuration)
    end

    it "returns a configuration after setup" do
      @klass.setup(@filename)
      @klass.configuration.should be_an_instance_of(Notable::Configuration)
    end
  end
end
