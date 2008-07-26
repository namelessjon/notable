require 'yaml'

module Notable
  class Configuration
    attr_accessor :config_file
    attr_reader :jabber_username, :jabber_password, :jabber_options, :database

    def initialize(filename)
      @config_file = filename
      @jabber_options = {}
      @database = {}
      parse_config
    end


    def set_jabber_options(options_hash)
      @jabber_username = options_hash.delete('username')
      unless jabber_username
        raise(Notable::BadConfiguration, "Must specificy a jabber username for the account")
      end

      @jabber_password = options_hash.delete('password')
      unless jabber_password
        raise(Notable::BadConfiguration, "Must specificy a jabber password for the account")
      end

      @jabber_options = options_hash
    end

    def set_database_options(options_hash)
      @database = options_hash
    end
    protected
    def parse_config
      config_hash = YAML.load_file(config_file)
      unless config_hash.has_key?('jabber')
        raise(Notable::BadConfiguration, "Must specify jabber configuration")
      else
        set_jabber_options(config_hash.delete('jabber'))
      end
      unless config_hash.has_key?('database')
        raise(Notable::BadConfiguration, "Must specify database configuration")
      else
        set_database_options(config_hash.delete('database'))
      end

    end
  end
end
