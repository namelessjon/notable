xml.instruct! :xml, :version => '1.1'
xml.rss 'version' => '2.0' do
  xml.channel do
    xml.title 'Notable'
    xml.link '/notable'
    xml.description 'Things that have been noted'
    @notes.each do |note|
      xml.item do
        xml.title note.body
        xml.description note.body
        xml.pubDate note.created_at.strftime('%a, %d %b %Y %H:%M:%S %Z')
      end
    end
  end
end
