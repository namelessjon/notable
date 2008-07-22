require 'rubygems'
require 'sinatra'
require 'lib/notable'

configure do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/notes.db")
  DataMapper.auto_upgrade!
  @note_taker = Notable::NoteTaker.new('notes.yml', true)
  @note_taker.connect
end

get '/' do
  @notes = Notable::Note.all(:order => [:created_at.desc])
  @notes_out = []
  @notes.each do |n|
    @notes_out << "<li>#{n.created_at} - #{n.body}</li>"
  end
  body "<ul>#{@notes_out.join("\n")}</ul>"
end

