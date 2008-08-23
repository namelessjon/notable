require "#{File.dirname(__FILE__)}/../spec_helper"
describe "Notable::Configuration" do
  before(:each) do
    @filename = "notable.yml"
    @jabber_hash = {'username' => 'a@b.c', 'password' => 'seekrit!', 'resource' => 'test_resource'}
    @database_hash = {'adapter' => 'sqlite3', 'database' => ':memory:'}
    @config_hash = { 'jabber' => @jabber_hash.dup, 'database' => @database_hash.dup }
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

      it "raises unless 'jabber' is a key" do
        @config_hash.delete('jabber')
        lambda { Notable::Configuration.new(@filename) }.should  raise_error(Notable::BadConfiguration, "Must specify jabber configuration")
      end

      it "raises unless 'database' is a key" do
        @config_hash.delete('database')
        lambda { Notable::Configuration.new(@filename) }.should  raise_error(Notable::BadConfiguration, "Must specify database configuration")
      end

      it "calls #set_jabber_options" do
        # this we test via deleting the username from the hash, and seeing if it
        # notices
        @config_hash['jabber'].delete('username')
        lambda { Notable::Configuration.new(@filename) }.should raise_error(Notable::BadConfiguration, "Must specificy a jabber username for the account")
      end
    end
  end


  describe '#set_jabber_options' do
    before(:each) do
      @c = Notable::Configuration.new(@filename)
    end

    it "responds to #set_jabber_options" do
      @c.should respond_to(:set_jabber_options)
    end

    it "can be passed a config hash" do
      lambda { @c.set_jabber_options(@jabber_hash) }.should_not raise_error(ArgumentError)
    end

    it "sets the jabber_username correctly" do
      @c.set_jabber_options(@jabber_hash)
      @c.jabber_username.should == 'a@b.c'
    end

    it "sets the jabber_password correctly" do
      @c.set_jabber_options(@jabber_hash)
      @c.jabber_password.should == 'seekrit!'
    end

    it "sets the jabber_resource correctly" do
      @c.set_jabber_options(@jabber_hash)
      @c.jabber_resource.should == 'test_resource'
    end
    it "sets the default for jabber_resource correctly" do
      @jabber_hash.delete('resource')
      @c.set_jabber_options(@jabber_hash)
      @c.jabber_resource.should == 'notable'
    end

    it "puts the rest in an options hash" do
      @c.set_jabber_options(@jabber_hash.merge('echo' => true))
      @c.jabber_options.should have_key('echo')
      @c.jabber_options['echo'].should == true
    end

    it "doesn't put the username in the options hash" do
      @c.set_jabber_options(@jabber_hash)
      @c.jabber_options.should_not have_key('username')
    end

    it "doesn't put the password in the options hash" do
      @c.set_jabber_options(@jabber_hash)
      @c.jabber_options.should_not have_key('password')
    end

    it "doesn't put the resource in the options hash" do
      @c.set_jabber_options(@jabber_hash)
      @c.jabber_options.should_not have_key('resource')
    end

    it "raises BadConfiguration if no username is set." do
      lambda { @c.set_jabber_options(Hash.new) }.should raise_error(Notable::BadConfiguration, /username/)
    end

    it "raises BadConfiguration if no password is set." do
      hash = {'username' => 'a@b.c'}
      lambda { @c.set_jabber_options(hash) }.should raise_error(Notable::BadConfiguration, /password/)
    end
    
    it "doesn't raise BadConfiguration if no resource is set." do
      hash = {'username' => 'a@b.c', 'password' => 'seeekrit'}
      lambda { @c.set_jabber_options(hash) }.should_not raise_error(Notable::BadConfiguration)
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


  describe "#jabber_options" do
    before(:each) do
      @c = Notable::Configuration.new(@filename)
    end
    it "responds to #jabber_options" do
      @c.should respond_to(:jabber_options)
    end
    it "is a hash on creation" do
      @c.jabber_options.should be_a_kind_of(Hash)
    end
    it "is empty on creation" do
      @c.jabber_options.should be_empty
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
