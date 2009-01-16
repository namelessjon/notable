begin
  require 'minigems'
rescue LoadError
  require 'rubygems'
end
gem('sinatra-sinatra')
require 'sinatra/base'

require 'lib/notable'

class Notes < Sinatra::Base

  configure do
    Notable.setup('notes.yml')
    Notable.connect
  end

  enable :static, :logging

  # helpers
  def link_to(url)
    "#{request.env['SCRIPT_NAME']}#{url}"
  end

  def format_note(note)
    "#{note.body} - <em>#{note.created_at.strftime('%H:%M')} #{note.created_at_to_s}</em>"
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
    @notes = Notable::Note.all(:order => [:created_at.desc])
    choose_format
  end

  ['/last/:count', '/last/', '/last'].each do |url|
    get url do
      count = params['count'].to_i
      if (count < 1)
        count = 5
      end
      @notes = Notable::Note.all(:order => [:created_at.desc],
                                 :limit => count)
      @title = "Last #{count} Notes"
      choose_format
    end
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
      response.headers['Location'] = link_to('/')
      body "Note created!\n"
    else
      throw :halt, [400, @note.errors.full_messages.join("\n") + "\n"]
    end
  end

  get '/notes.txt' do
    @notes = sort_notes(Notable::Note.all(:order => [:created_at.desc]))
    out = []
    @notes.each do |day|
      out << day.first
      day.last.each do |n|
        out << "  " + n
      end
    end
    body out.join("\n") + "\n"
  end

  get '/notable.rss' do
    @notes = Notable::Note.all(:order => [:created_at.desc])
    content_type :xml
    builder :rss
  end

  get '/style.css' do
    content_type :css
    <<-eos
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
