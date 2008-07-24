
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

    # connect to the Jabber server with NoteTaker's credentials
    def handshake
      client.connect
      client.auth(@password)
      set_available
    end

    # set the client to available
    def set_available
      client.send(Jabber::Presence.new)
    end

    # register the callbacks for message handling
    def register_callbacks
      client.add_message_callback do |m|
        if m.type != :error
          process_message(m)
        end
      end
    end

    # processes the message, acting on the command it contains, or saving the
    # message to the database, as appropriate
    def process_message(message)
      body = message.body.strip
      save_message(message)
      echo_message(message) if echo
    end

    ##
    # sends a message via the client.
    #
    #
    def send_message(to, body, type)
      reply = Jabber::Message.new(to, body)
      reply.type = type
      client.send(reply)
    end

    ##
    # echos the body of the message back to the sender
    def echo_message(message)
      send_message(message.from, "Received: #{message.body}", message.type)
    end

    ##
    # Saves the message to the database.
    def save_message(message)
      Note.create(:body => message.body.strip)
    end

    # connects and registers the callback which will save messages
    def connect
      handshake
      register_callbacks
    end

    protected
    def parse_options_hash(options)
      @echo = options.delete('echo') if options.has_key?('echo')
    end

  end
end
