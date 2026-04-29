$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

# exclude warnings in 3rd party code
module WarningFilter
  def warn(message, category: nil)
    super unless Gem.path.any? { |p| message.include?(p) }
  end
end
Warning.prepend(WarningFilter)

require 'beaker-abs'
require 'beaker'

require 'minitest/autorun'
