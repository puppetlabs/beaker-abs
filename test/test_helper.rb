$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'beaker-abs'
require 'beaker'

require "logger"
require 'minitest/autorun'
require 'webmock/minitest'

WebMock.disable_net_connect!

def create_logger(io)
  Beaker::Logger.new(io, :quiet => true)
end
