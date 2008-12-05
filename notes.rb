begin
  require 'minigems'
rescue LoadError
  require 'rubygems'
end
require 'sinatra'
require 'lib/notable'

configure do
  Notable.setup('notes.yml')
  Notable.connect
end

helpers do
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
end



get '/' do
  @notes = sort_notes(Notable::Note.all(:order => [:created_at.desc]))
  haml :index
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
  builder :rss
end

