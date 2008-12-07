require "#{File.dirname(__FILE__)}/../spec_helper"
describe "Notable::Configuration" do
  before(:each) do
    @filename = "notable.yml"
    @database_hash = {'adapter' => 'sqlite3', 'database' => ':memory:'}
    @config_hash = { 'database' => @database_hash.dup }
    YAML.stub!(:load_file).and_return(@config_hash.dup)
  end


  describe "#config_file" do
    before(:each) do
      @c = Notable::Configuration.new(@filename)
    end

    it "responds to #config_file" do
      @c.should respond_to(:config_file)
    end

    it "responds to #config_file=" do
      @c.should respond_to(:config_file=)
    end
  end


  describe "#new" do
    describe "YAML loading" do
      before(:each) do
        YAML.should_receive(:load_file).with(@filename).and_return(@config_hash)
      end

      it "loads the file with YAML" do
        Notable::Configuration.new(@filename)
      end

      it "raises unless 'database' is a key" do
        @config_hash.delete('database')
        lambda { Notable::Configuration.new(@filename) }.should  raise_error(Notable::BadConfiguration, "Must specify database configuration")
      end

    end
  end

  describe '#set_database_options' do
    before(:each) do
      @c = Notable::Configuration.new(@filename)
    end

    it "responds to #set_database_options" do
      @c.should respond_to(:set_database_options)
    end

    it "can be passed a config hash" do
      lambda { @c.set_database_options(@database_hash) }.should_not raise_error(ArgumentError)
    end

    it "sets the database_username correctly" do
      @c.set_database_options(@database_hash)
      @c.database.should == @database_hash
    end
  end

  describe "#database" do
    before(:each) do
      @c = Notable::Configuration.new(@filename)
    end
    it "responds to #database" do
      @c.should respond_to(:database)
    end
    it "is a hash on creation" do
      @c.database.should be_a_kind_of(Hash)
    end
    it "isn't empty on creation" do
      @c.database.should_not be_empty
    end
  end
end
