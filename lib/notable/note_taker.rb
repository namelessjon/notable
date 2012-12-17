require 'uppercut'
require 'yajl'
require 'rest_client'
require 'daemons'

class NoteTaker < ::Uppercut::Agent
  attr_accessor :opts
  def initialize(opts)
	@opts = opts
    super(opts['jabber_username'], opts['jabber_password'], :connect => false)
  end


  command(/^last ?(\d+)?$/) do |c, rest|
    num = (rest.first.nil?) ? 5 : rest.first.to_i
    notes = get("/notes?num=#{num}")
    c.send(notes.map {|n| n['body'] }.join("\n"))
  end

  command(/^search ?(\w+)?$/) do |c, term|
    if term.first.nil?
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
  def setup_resource
    if (opts['http_username']&&opts['http_password'])
      ::RestClient::Resource.new(opts['url'],
                                   opts['http_username'], opts['http_password'])
    else
      ::RestClient::Resource.new(opts['url'])
    end
  end

  def r
    @resource ||= setup_resource
  end

  def get(url, headers={})
    ::Yajl::Parser.parse(r[url].get(headers.merge({:accept => 'application/json'})))
  end
end
