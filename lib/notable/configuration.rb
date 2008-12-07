require 'yaml'

module Notable
  class Configuration
    attr_accessor :config_file
    attr_reader :database

    def initialize(filename)
      @config_file = filename
      @database = {}
      parse_config
    end


    def set_database_options(options_hash)
      @database = options_hash
    end
    protected
    def parse_config
      config_hash = YAML.load_file(config_file)
      unless config_hash.has_key?('database')
        raise(Notable::BadConfiguration, "Must specify database configuration")
      else
        set_database_options(config_hash.delete('database'))
      end

    end
  end
end
