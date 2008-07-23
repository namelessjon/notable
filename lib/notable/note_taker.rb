
module Notable
  class NoteTaker
    attr_reader :client
    attr_accessor :echo

    def initialize(username, password, options={})
      @password = password
      @client = Jabber::Client.new("#{username}/notable")
      @echo = false
      parse_options_hash(options)
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
    def parse_options_hash(options)
      @echo = options.delete('echo') if options.has_key?('echo')
    end
  end
end
