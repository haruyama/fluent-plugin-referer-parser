require 'bundler/setup'
require 'test/unit'

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)
require 'fluent/test'
unless ENV.key?('VERBOSE')
  nulllogger = Object.new
  nulllogger.instance_eval do |obj|
    def method_missing(method, *args)
      # pass
    end
  end
  $log = nulllogger
end

class Test::Unit::TestCase
end
