require "#{File.dirname(__FILE__)}/spec_helper"

describe 'Notable::NoteTaker' do
  describe "#new" do
    describe "with no options" do
      before(:each) do
        @username = 'test_user@example.com'
        @password = 'example_password'
        @note_taker = Notable::NoteTaker.new(@username, @password)
      end
      it "creates a client" do
        @note_taker.client.should_not be_nil
      end
      it "assigns the correct domain to a new client" do
        @note_taker.client.jid.to_s.should match(/^#{@username}/)
      end
      it "assigns the resource type of the client as notable" do
        @note_taker.client.jid.resource.should == 'notable'
      end
    end

    describe "options" do
      describe "echo" do
        before(:each) do
          @username = 'test_user@example.com'
          @password = 'example_password'
        end
        it "responds to echo" do
          @note_taker = Notable::NoteTaker.new(@username, @password)
          @note_taker.should respond_to(:echo)
        end
        it "responds to echo=" do
          @note_taker = Notable::NoteTaker.new(@username, @password)
          @note_taker.should respond_to(:echo=)
        end
        it "defaults to false" do
          @note_taker = Notable::NoteTaker.new(@username, @password)
          @note_taker.echo.should == false
        end
        it "is parsed from the options hash" do
          @note_taker = Notable::NoteTaker.new(@username, @password, {'echo' => true})
          @note_taker.echo.should == true
        end
      end
    end
  end


  describe do
    # mock the client, mostly so we can check its methods are called correctly
    before(:each) do
      @username = 'test_user@example.com'
      @password = 'example_password'
      @note_taker = Notable::NoteTaker.new(@username, @password)
      @client = mock('client', :null_object => true)
      @note_taker.instance_variable_set(:@client, @client)
      @note_taker.stub!(:save_message)
    end


    describe "#set_available" do
      it "responds to set_available" do
        @note_taker.should respond_to(:set_available)
      end
      # I should make two specs of this, but it's hard, as Jabber::Client
      # redefines send
      it "calls send on the client with the new presence" do
        @client.should_receive(:send).with(:presence)
        Jabber::Presence.should_receive(:new).and_return(:presence)
        @note_taker.set_available
      end
    end


    describe "#handshake" do
      it "responds to handshake" do
        @note_taker.should respond_to(:handshake)
      end
      it "calls connect on the client" do
        @client.should_receive(:send)
        @client.should_receive(:connect).once
        @note_taker.handshake
      end
      it "calls auth on the client" do
        @client.should_receive(:send)
        @client.should_receive(:auth).once
        @note_taker.handshake
      end
      it "calls auth on the client with the password" do
        @client.should_receive(:send)
        @client.should_receive(:auth).once.with(@password)
        @note_taker.handshake
      end
      it "calls set_available on self" do
        @note_taker.should_receive(:set_available)
        @note_taker.handshake
      end
    end


    describe "#register_callbacks" do
      it "responds to register callbacks" do
        @note_taker.should respond_to(:register_callbacks)
      end
      it "calls add_message_callback on the client" do
        @client.should_receive(:add_message_callback)
        @note_taker.register_callbacks
      end
      describe do
        before(:each) do
          @m = mock('message', :null_object => true)
          @note_taker.stub!(:process_message)
        end
        it "calls add_message_callback with a block" do
          @client.should_receive(:add_message_callback).and_yield(@m)
          @note_taker.register_callbacks
        end
        it "finds the type of the message" do
          @m.should_receive(:type)
          @client.should_receive(:add_message_callback).and_yield(@m)
          @note_taker.register_callbacks
        end
        it "calls process_message if type != error" do
          @m.should_receive(:type)
          @client.should_receive(:add_message_callback).and_yield(@m)
          @note_taker.should_receive(:process_message)
          @note_taker.register_callbacks
        end
        it "passes the message to process_message if type != error" do
          @m.should_receive(:type)
          @client.should_receive(:add_message_callback).and_yield(@m)
          @note_taker.should_receive(:process_message).with(@m)
          @note_taker.register_callbacks
        end
        it "doesn't call process_message if the message is an error" do
          @m.should_receive(:type).and_return(:error)
          @client.should_receive(:add_message_callback).and_yield(@m)
          @note_taker.should_not_receive(:process_message)
          @note_taker.register_callbacks
        end
      end
    end


    describe "#process_message" do
      it "responds to #process_message" do
        @note_taker.should respond_to(:process_message)
      end
      it "saves an ordinary message" do
        @m = mock('message', :body => 'write more specs!')
        @note_taker.should_receive(:save_message).with(@m)
        @note_taker.process_message(@m)
      end

      describe "echoing" do
        before(:each) do
          @m = mock('message', :body => 'write more specs!',
                    :type => :normal, :from => :from )
          @note_taker.echo = true
        end
        it "calls echo_message when echo is true" do
          @note_taker.should_receive(:echo_message)
          @note_taker.process_message(@m)
        end
        it "calls echo_message with the message when echo is true" do
          @note_taker.should_receive(:echo_message).with(@m)
          @note_taker.process_message(@m)
        end
        it "doesn't call echo_message when echo is false" do
          @note_taker.should_not_receive(:echo_message).with(@m)
          @note_taker.echo = false
          @note_taker.process_message(@m)
        end
      end
    end


    describe "#send_message" do
      it "reponds to #send_message" do
        @note_taker.should respond_to(:send_message)
      end
      it "contructs an appropriate message" do
        m = mock('m')
        m.should_receive(:type=).with(:type)
        Jabber::Message.should_receive(:new).with(:from, :body).and_return(m)
        @client.stub!(:send)
        @note_taker.send_message(:from, :body, :type)
      end
      it "sends it via the client" do
        m = mock('m')
        m.should_receive(:type=).with(:type)
        Jabber::Message.should_receive(:new).with(:from, :body).and_return(m)
        @client.should_receive(:send).with(m)
        @note_taker.send_message(:from, :body, :type)
      end
    end


    describe "#echo_message" do
        before(:each) do
          @m = mock('message', :body => 'A message body',
                    :type => :normal, :from => :from )
        end
      it "reponds to #echo_message" do
        @note_taker.should respond_to(:echo_message)
      end
      it "calls #send_message with to, body and type" do
        @note_taker.should_receive(:send_message).with(:from, 'Received: A message body',
                                                       :normal)
        @note_taker.echo_message(@m)
      end
    end


    describe "#save_message" do
      it "reponds to #save_message" do
        @note_taker.should respond_to(:save_message)
      end
    end

    describe "#connect" do
      it "reponds to connect" do
        @note_taker.should respond_to(:connect)
      end
      it "connects and registers call_backs" do
        @note_taker.should_receive(:handshake).once.ordered
        @note_taker.should_receive(:register_callbacks).once.ordered
        @note_taker.connect
      end
    end
  end
end
