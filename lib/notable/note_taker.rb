begin
  require 'minigems'
rescue LoadError
  require 'rubygems'
end

gem('tyler-uppercut')
require 'uppercut'

gem('json')
require 'json/ext'

gem('rest-client')
require 'rest_client'

require 'daemons'

class NoteTaker < ::Uppercut::Agent
  def initialize(opts)
    setup_resource(opts)
    super(opts['jabber_username'], opts['jabber_password'], :connect => false)
  end


  command(/^last ?(\d+)?$/) do |c, rest|
    last = rest.to_i unless rest.nil?
    notes = get("/last/#{last}")
    c.send(notes.map {|n| n['body'] }.join("\n"))
  end

  command(/^search ?(\w+)?$/) do |c, term|
    if term.nil?
      c.send("Send a search term. e.g 'search todo'")
    else
      notes = get("/search?q=#{term}")
      string = <<-eos
        Results for #{term}:
      #{notes.map {|n| n['body'] }.join("\n")}
        eos
      c.send(string)
    end
  end

  command(/^(.*)$/m) do |c, rest|
    begin
      c.send(r.post(:note => rest))
    rescue RestClient::RequestFailed => e
      c.send("Failed: #{e.response.body}")
    end
  end

  protected
  def setup_resource(opts)
    if (opts['http_username']&&opts['http_password'])
      @@resource = ::RestClient::Resource.new(opts['url'],
                                   opts['http_username'], opts['http_password'])
    else
      @@resource = ::RestClient::Resource.new(opts['url'])
    end
  end

  def self.r
    @@resource
  end

  def self.get(url, opts={})
    ::JSON.parse(r[url].get(opts.merge({:accept => 'application/json'})))
  end
end
