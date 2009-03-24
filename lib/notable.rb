require 'dm-core'
require 'dm-timestamps'
require 'dm-serializer'
require 'dm-validations'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}"

module Notable
end

require 'notable/app'
require 'notable/note'


