require 'rubygems'
require 'xmpp4r'
require 'dm-core'
require 'dm-timestamps'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}"

module Notable
end

require 'notable/note'
require 'notable/note_taker'
