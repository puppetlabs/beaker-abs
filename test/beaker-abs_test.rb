require 'test_helper'
require 'beaker-abs/version'

class Beaker::AbsTest < Minitest::Test
  def test_that_it_has_a_version_number
    assert_match(/\d+\.\d+\.\d+/, BeakerAbs::Version::STRING)
  end
end
