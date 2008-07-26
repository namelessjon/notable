require 'rubygems'
require 'sinatra'
require 'lib/notable'

configure do
  Notable.setup('notes.yml')
  Notable.connect
end

get '/' do
  @notes = Notable::Note.all(:order => [:created_at.desc])
  @notes_out = []
  @notes.each do |n|
    @notes_out << "<li>#{n.created_at} - #{n.body}</li>"
  end
  body "<ul>#{@notes_out.join("\n")}</ul>"
end

