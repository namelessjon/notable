require 'sinatra/base'
require 'haml'

class Notable::App < Sinatra::Base

  configure do
    DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3:notes.db')
    DataMapper.auto_upgrade! if !test? and DataMapper.respond_to?(:auto_upgrade!)
  end

  # helpers
  def link_to(url = '/')
    "#{request.script_name}#{url}"
  end

  def hostname
    url = request.scheme + "://"
    url << request.host

    if request.scheme == "https" && request.port != 443 ||
      request.scheme == "http" && request.port != 80
      url << ":#{request.port}"
    end
    url
  end

  def absolute_url(url = '/')
    "#{hostname}#{link_to(url)}"
  end

  def format_note(note)
    "#{note.html_body} - <em>#{note.created_at.strftime('%H:%M')} #{note.created_at_to_s}</em>"
  end

  def choose_format
    case request.env['HTTP_ACCEPT']
    when 'application/json'
      content_type 'application/json'
      body(@notes.to_json)
    else
      body(haml(:index))
    end
  end

  def sort_notes(notes)
    a = []
    notes.each do |n|
      if a.empty?
        a.push [n.created_at_to_s, [n.body]]
      else
        if a.last.first == n.created_at_to_s
          a.last.last.push(n.body)
        else
          a.push [n.created_at_to_s, [n.body]]
        end
      end
    end
    a
  end



  get '/' do
    last_modified(Notable::Note.max(:created_at) || Time.at(0))

    @notes = Notable::Note.all(:order => [:created_at.desc], :limit => 20)
    choose_format
  end

  get '/notes' do
    count = params['num'].to_i
    if (count < 1)
      count = 20
    end

    @notes = Notable::Note.all(:order => [:created_at.desc],
                               :limit => count)
    @title = "Last #{count} Notes"
    choose_format
  end

  get '/search' do
    @title = "Notes - #{params['q']}"
    @notes = Notable::Note.all(:body.like => "%#{params['q']}%")
    choose_format
  end

  post '/' do
    note_body = params['note'] || request.body.read

    @note = Notable::Note.new(:body => note_body)
    if @note.save
      status 201
      response['Location'] = link_to
      body "Note created!\n"
    else
      throw :halt, [400, @note.errors.full_messages.join("\n") + "\n"]
    end
  end

  get '/notes.txt' do
    last_modified(Notable::Note.max(:created_at))
    @notes = sort_notes(Notable::Note.all(:order => [:created_at.desc]))
    out = []
    @notes.each do |day|
      out << day.first
      day.last.each do |n|
        out << "  " + n
      end
    end
    content_type :text
    body out.join("\n") + "\n"
  end

  get '/notable.rss' do
    @last_modified = Notable::Note.max(:created_at)

    content_type :xml
    last_modified(@last_modified ? @last_modified : Time.at(0))


    @notes = Notable::Note.all(:order => [:created_at.desc], :limit => 20)
    haml :rss
  end

  get '/style.css' do
    content_type :css
    last_modified File.mtime(__FILE__)
    body = <<-eos
@import url("http://yui.yahooapis.com/2.6.0/build/reset-fonts-grids/reset-fonts-grids.css");
html {
  font-size: 62.5%;
  font-family: "Tahoma";
}
body {
  background-color: #333;
  height: 100%;
  position: absolute;
  left: 0;
  right: 0;
}
#doc {
  background-color: #ddd;
  bottom: 0;
  top: 0;
  position: absolute;
  margin-left: auto;
  margin-right: auto;
}
#container {
  margin-left: auto;
  margin-right: auto;
  min-width: 750px;
  width: 59.97em;
}
ul {
  margin: 20px 20px 20px 20px;
}
li {
  display: block;
  margin-top: 5px;
  margin-bottom: 5px;
  padding-bottom: 2px;
  padding-top: 2px;
}
em {
  font-style: italic;
  color: #fff;
}
h1 {
  font-size: 3em;
}
eos
  end
end
