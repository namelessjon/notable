require File.join(File.dirname(__FILE__), "spec_helper")

# make sure we'll connect to a temporary db, not any one that matters
ENV['DATABASE_URL'] = 'sqlite3::memory:'
require File.join(File.dirname(__FILE__), '..', 'lib', 'notable')

# require some bits and bobs to help
require 'rack/test'
require 'hpricot'
require 'json'

# setup everything for bacon!
class Bacon::Context
  include Rack::Test::Methods

  def app
    Notable::App.new
  end

  def parsed_body
    Hpricot(last_response.body.to_s)
  end

  def parsed_xml
    Hpricot::XML(last_response.body.to_s)
  end

  def parsed_json
    JSON.parse(last_response.body.to_s)
  end

  def get_json(route, params = {}, env = {}, &block)
    get(route, params, env.merge('HTTP_ACCEPT' => 'application/json'), &block)
  end

end

describe 'Notes' do
  before do
    DataMapper.auto_migrate!
  end

  describe "get '/' in a new app" do
    before do
      get '/'
    end

    it "has a / route" do
      last_response.should.be.ok
    end

    it "has a list of nodes" do
      parsed_body.at('//body//ul').should.not.be.nil
    end

    it "the list is empty" do
      parsed_body.at('//body//ul/li').should.be.nil
    end
  end

  describe "post '/' with a valid note" do
    before do
      post '/', :note => 'A new note!'
    end

    it "returns 201 Created" do
      last_response.status.should.equal 201
    end

    it "returns `Note created!'" do
      last_response.body.should.include("Note created!\n")
    end

    it "returns '/' in the location header" do
      last_response['Location'].should.equal '/'
    end

    it "actually creates a note" do
      get '/'
      parsed_body.at('//body//li').should.not.be.nil
      parsed_body.at('//body//li').inner_html.should.match(/^A new note!/)
    end
  end

  describe "post '/' with a body" do
    before do
      post '/', {}, :input => 'A new note!'
    end

    it "returns 201 Created" do
      last_response.status.should.equal 201
    end

    it "returns `Note created!'" do
      last_response.body.should.include("Note created!\n")
    end

    it "returns '/' in the location header" do
      last_response['Location'].should.equal '/'
    end

    it "actually creates a note" do
      get '/'
      parsed_body.at('//body//li').should.not.be.nil
      parsed_body.at('//body//li').inner_html.should.match(/^A new note!/)
    end
  end

  describe "post '/' without a valid note" do
    before do
      post '/'
    end

    it "returns 400 Bad Request" do
      last_response.status.should.equal 400
    end

    it "returns appropriate errors" do
      last_response.body.should.include("Body must not be blank\n")
    end
  end

  describe "get '/last(/:n)'" do
    before do
      %w{a b c d e f}.each do |note|
        post '/', :note => note
      end
    end

    it "gets 5 by default" do
      get '/last'
      parsed_body.search('//body//li').size.should.equal 5
    end

    it "gets 1 when you ask for it" do
      get '/last/1'
      parsed_body.search('//body//li').size.should.equal 1
    end

    it "gets more than 5 when you ask for it" do
      get '/last/7'
      parsed_body.search('//body//li').size.should.equal 6
    end

    it "gets five when you give it a silly request" do
      get '/last/foo'
      parsed_body.search('//body//li').size.should.equal 5
    end
  end

  describe "get '/search?q='" do
    before do
      %w{foo bar baz}.each do |note|
        post '/', :note => note
      end
      get '/search?q=a'
    end

    it "is successful" do
      last_response.status.should.equal 200
    end

    it "returns notes which match" do
      parsed_body.at('//li[text()^="bar"]').should.not.be.nil
      parsed_body.at('//li[text()^="baz"]').should.not.be.nil
    end
    it "doesn't return notes which don't match" do
      parsed_body.at('//li[text()^="foo"]').should.be.nil
    end
  end

  describe "get '/notable.rss'" do
    before do
      %w{foo bar baz}.each do |note|
        post '/', :note => note
      end
      get '/notable.rss'
    end

    it "is successful" do
      last_response.should.be.ok
    end

    it "has the `application/xml' mime-type" do
      last_response.content_type.should.equal 'application/xml'
    end

    it "is an rss 2.0 feed" do
      parsed_xml.at('/rss[@version="2.0"]').should.not.be.nil
    end

    it "has the correct title" do
      parsed_xml.at('/rss/channel/title[text()="Notable"]').should.not.be.nil
    end

    it "has the correct link" do
      parsed_xml.at('/rss/channel/link[text()="http://example.org:80/"]').should.not.be.nil
    end

    it "has the correct number of items" do
      parsed_xml.search('/rss/channel/item').size.should.equal 3
    end

    describe "an item" do
      before do
        @item = parsed_xml.at('/rss/channel/item')
      end

      it "has the correct title" do
        @item.at('/title[text()="foo"]').should.not.be.nil
      end

      it "has the correct description" do
        @item.at('/description[text()="foo"]').should.not.be.nil
      end

      it "has a timestamp in the correct format" do
        @item.at('/pubDate').inner_html.should.match(/\w{3}, \d{2} \w{3} \d{4} \d{2}\:\d{2}\:\d{2} GMT/)
      end
    end
  end

  describe 'JSON requests' do
    describe "get '/' in a new app" do
      before do
        get_json '/'
      end

      it "has a / route" do
        last_response.should.be.ok
      end

      it "returns the correct mime-type" do
        last_response.content_type.should.equal 'application/json'
      end

      it "returns an empty array" do
        parsed_json.should.equal []
      end
    end

    describe "with some notes" do
      before do
        %w{bat cat dog giraffe dolphin pony}.each do |note|
          post '/', :note => note
        end
      end

      describe "get '/'" do
        before do
          get_json '/'
          @item = parsed_json.first
        end

        it "returns an array of the items" do
          parsed_json.size.should.equal 6
        end

        it "returns an array of hashes" do
          @item.class.should.equal Hash
          @item.should.has_key('id')
          @item.should.has_key('body')
          @item.should.has_key('created_at')
        end
      end

      describe "get '/last'" do
        it "gets 5 by default" do
          get_json '/last'
          parsed_json.size.should.equal 5
        end

        it "gets 1 when you ask for it" do
          get_json '/last/1'
          parsed_json.size.should.equal 1
        end

        it "gets more than 5 when you ask for it" do
          get_json '/last/7'
          parsed_json.size.should.equal 6
        end

        it "gets five when you give it a silly request" do
          get_json '/last/foo'
          parsed_json.size.should.equal 5
        end
      end
      describe "get '/search?q='" do
        before do
          get_json '/search?q=o'
          @json = parsed_json
        end

        it "is successful" do
          last_response.should.be.ok
        end

        it "returns notes which match" do
          @json.size.should.equal 3
          @json.detect { |hash| hash['body'] == 'dog' }.should.not.be.nil
          @json.detect { |hash| hash['body'] == 'dolphin' }.should.not.be.nil
          @json.detect { |hash| hash['body'] == 'pony' }.should.not.be.nil
        end
        it "doesn't return notes which don't match" do
          @json.detect { |hash| hash['body'] == 'cat' }.should.be.nil
        end
      end
    end
  end
end



