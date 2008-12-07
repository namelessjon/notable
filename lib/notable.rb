begin
  require 'minigems'
rescue LoadError
  require 'rubygems'
end
require 'dm-core'
require 'dm-timestamps'
require 'dm-serializer'
require 'dm-validations'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}"

require 'notable/note'
require 'notable/configuration'

module Notable
  class BadConfiguration < StandardError; end;

  ##
  # Creates a new configuration from the given filename and saves it in a class
  # variable.
  #
  # At a minimum the configuration should offer jabber username and
  # password, and details of the database
  #
  # The configuration is used to set up a NoteTaker
  def self.setup(filename)
    @@configuration = Configuration.new(filename)
  end

  ##
  # Connects to the database and to the jabber service
  def self.connect
    DataMapper.setup(:default, configuration.database)
  end

  ##
  # Provides access to the Configuration
  def self.configuration
    @@configuration
  end
end

