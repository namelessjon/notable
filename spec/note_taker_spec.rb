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
end
