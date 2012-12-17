require File.join(File.dirname(__FILE__), "spec_helper")

# make sure we'll connect to a temporary db, not any one that matters
ENV['DATABASE_URL'] = 'sqlite3::memory:'

# also make sure we're in the test env.  This will make errors so much saner
ENV['RACK_ENV']     = 'test'

require File.join(File.dirname(__FILE__), '..', 'lib', 'notable')

# require some bits and bobs to help
require 'rack/test'
require 'nokogiri'
require 'json'
require 'timecop'
require 'dm-migrations'

# setup everything for bacon!
class Bacon::Context
  include Rack::Test::Methods

  def app
    Notable::App.new
  end

  def parsed_body
    Nokogiri.parse(last_response.body.to_s)
  end

  def parsed_xml
    Nokogiri::XML.parse(last_response.body.to_s)
  end

  def parsed_json
    JSON.parse(last_response.body.to_s)
  end

  def get_json(route, params = {}, env = {}, &block)
    get(route, params, env.merge('HTTP_ACCEPT' => 'application/json'), &block)
  end

end

DataMapper.auto_migrate!
Notable::App.root = File.join(File.dirname(__FILE__), '..')



describe 'Notable::App (pristine)' do
  describe "get '/'" do
    describe "HTML" do
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

    describe "JSON" do
      before do
        get_json '/'
      end

      it "has a / route" do
        last_response.should.be.ok
      end

      it "returns the correct mime-type" do
        last_response.content_type.should.include 'application/json'
      end

      it "returns an empty array" do
        parsed_json.should.equal []
      end
    end
  end
  describe "get '/style.css'" do
    before do
      get '/style.css'
    end

    it "should be succesful" do
      last_response.should.be.ok
    end

    it "should have `text/css' content type" do
      last_response.content_type.should.include 'text/css'
    end

    it "should have a `Last-Modified' header" do
      last_response.headers.should.has_key('Last-Modified')
    end
  end
end

describe "Notable::App - Note Creation" do
  before do
    DataMapper.auto_migrate!
  end

  describe "post '/' with note params" do
    before do
      post '/', :note => 'A new note!'
    end

    it "returns 201 Created" do
      last_response.status.should.equal 201
    end

    it "returns `Note created!'" do
      last_response.body.should.include("Note created!\n")
    end

    it "returns the correct location header" do
      last_response['Location'].should.equal 'http://example.org/'
    end

    it "actually creates a note" do
      get '/'
      parsed_body.at('//body//li').should.not.be.nil
      parsed_body.at('//body//li').inner_html.should.match(/^A new note!/)
    end
  end

  describe "post '/' with a body" do
    before do
      post '/', {}, :input => 'A new note! http://www.example.com'
    end

    it "returns 201 Created" do
      last_response.status.should.equal 201
    end

    it "returns `Note created!'" do
      last_response.body.should.include("Note created!\n")
    end

    it "returns the correct location header" do
      last_response['Location'].should.equal 'http://example.org/'
    end

    it "actually creates a note" do
      get '/'
      parsed_body.at('//body//li').should.not.be.nil
      parsed_body.at('//body//li').inner_html.should.match(/^A new note!/)
    end

    it "converts a URL to a link" do
      get '/'
      parsed_body.at('//body//li').at('a').should.not.be.nil
      parsed_body.at('//body//li').at('a')[:href].should.equal 'http://www.example.com'
      parsed_body.at('//body//li').at('a').inner_html.should.equal 'http://www.example.com'
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
end



describe "With Some Notes" do
  before do
    DataMapper.auto_migrate!
    @link = 'http://example.net'
    @link_note = "A test #{@link}"
    @notes =  %w{bat cat dog dolphin giraffe pony 11 22 33 44 55 66 77 88 99 1010 1111 1212 1313 1414} + [@link_note]
    @notes.each_with_index do |n, i|
      Timecop.travel(2009, 3, 25, 10, 10, i) do
        post '/', :note => n
      end
    end
  end

  describe "HTML" do
    describe "get '/'" do
      before do
        get '/'
      end

      it "should be successful" do
        last_response.should.be.ok
      end

      it "should have at most 20 items in a list" do
        parsed_body.search('//body//li').size.should.equal 20
      end
    end

    describe "get '/notes'" do
      it "gets 20 by default" do
        get '/notes'
        parsed_body.search('//body//li').size.should.equal 20
      end

      it "gets 1 when you ask for it" do
        get '/notes?num=1'
        parsed_body.search('//body//li').size.should.equal 1
      end

      it "gets more than 20 when you ask for it" do
        get '/notes?num=21'
        parsed_body.search('//body//li').size.should.equal 21
      end

      it "gets 20 when you give it a silly request" do
        get '/notes?num=foo'
        parsed_body.search('//body//li').size.should.equal 20
      end
    end

    describe "get '/search?q='" do
      before do
        get '/search?q=g'
      end

      it "is successful" do
        last_response.status.should.equal 200
      end

      it "returns notes which match" do
        parsed_body.at('//li[contains(text(),"giraffe")]').should.not.be.nil
        parsed_body.at('//li[contains(text(),"dog")]').should.not.be.nil
      end
      it "doesn't return notes which don't match" do
        (@notes - %w{giraffe dog}).each do |n|
          parsed_body.at("//li[contains(text(),'#{n}')]").should.be.nil
        end
      end
    end
  end

  describe 'JSON' do
    describe "get '/'" do
      before do
        get_json '/'
        @item = parsed_json.first
      end

      it "returns an array of the items, at most 20 items in size" do
        parsed_json.size.should.equal 20
      end

      it "returns an array of hashes" do
        @item.class.should.equal Hash
        @item.should.has_key('id')
        @item.should.has_key('body')
        @item.should.has_key('created_at')
      end
    end

    describe "get '/notes'" do
      it "gets 20 by default" do
        get_json '/notes'
        parsed_json.size.should.equal 20
      end

      it "gets 1 when you ask for it" do
        get_json '/notes?num=1'
        parsed_json.size.should.equal 1
      end

      it "gets more than 20 when you ask for it" do
        get_json '/notes?num=21'
        parsed_json.size.should.equal 21
      end

      it "gets twenty when you give it a silly request" do
        get_json '/notes?num=foo'
        parsed_json.size.should.equal 20
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

  describe "get '/notable.rss'" do
    before do
      get '/notable.rss'
    end

    it "is successful" do
      last_response.should.be.ok
    end

    it "has the `application/xml' mime-type" do
      last_response.content_type.should.include 'application/xml'
    end

    it "has a `Last-Modified' header" do
      last_response.headers.should.has_key('Last-Modified')
    end

    it "is an rss 2.0 feed" do
      parsed_xml.at('/rss[@version="2.0"]').should.not.be.nil
    end

    it "has the correct title" do
      parsed_xml.at('/rss/channel/title[text()="Notable"]').should.not.be.nil
    end

    it "has the correct link" do
      parsed_xml.at('/rss/channel/link[text()="http://example.org/"]').should.not.be.nil
    end

    it "returns at most 20 items" do
      parsed_xml.search('/rss/channel/item').size.should.equal 20
    end

    describe "an item" do
      before do
        @item = parsed_xml.at('/rss/channel/item')
      end

      it "has the correct title" do
        @item.at('title').inner_html.should.equal @link_note
      end

      it "has the correct description, with html escaped." do
        @item.at('description').inner_html.should.equal %Q|A test &lt;a href="#{@link}"&gt;#{@link}&lt;/a&gt;|
      end

      it "has the correct timestamp" do
        @item.at('pubDate').inner_html.should.equal("Wed, 25 Mar 2009 10:10:20 GMT")
      end
    end
  end
end

