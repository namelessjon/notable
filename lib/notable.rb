begin
  require 'minigems'
rescue LoadError
  require 'rubygems'
end
require 'dm-core'
require 'dm-timestamps'
require 'dm-serializer'
require 'dm-validations'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}"

require 'notable/note'

module Notable
end

