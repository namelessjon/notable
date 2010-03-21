require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'

$LOAD_PATH.unshift "#{::File.dirname(__FILE__)}"

module Notable
end

require 'notable/note'
require 'notable/app'


