xml.instruct! :xml, :version => '1.1'
xml.rss 'version' => '2.0' do
  xml.channel do
    xml.title 'Notable'
    xml.link link_to('/notable')
    xml.description 'Things that have been noted'
    xml.image 'title' => 'notable', 'url' => link_to('feed_edit.png'), 'link' => link_to('/notable')
    @notes.each do |note|
      xml.item do
        xml.title note.body
        xml.description note.body
        xml.pubDate note.created_at.new_offset.strftime('%a, %d %b %Y %H:%M:%S GMT')
      end
    end
  end
end
