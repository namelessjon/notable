require 'yaml'

module Notable
  class NoteTaker
    def initialize(config_file, echo = true)
      username, password = parse_config(config_file)
      @jid = Jabber::JID::new("#{username}/notetaker")
      @pass = password
      @client = Jabber::Client.new(@jid)
      @echo = echo
    end

    # connects and registers the callback which will save messages
    def connect
      @client.connect
      @client.auth(@pass)
      @client.send(Jabber::Presence.new.set_type(:available))
      @client.add_message_callback do |m|
        if m.type != :error
          Note.create(:body => m.body.strip)
          if @echo
            reply = Jabber::Message.new(m.from, "You sent: #{m.body}")
            reply.type = m.type
            @client.send(reply)
          end
        end
      end
    end

    protected

    def parse_config(config_file)
      config = YAML.load_file(config_file)
      username = config.delete('username') if config.has_key?('username')
      password = config.delete('password') if config.has_key?('password')
      return username, password
    end
  end
end
