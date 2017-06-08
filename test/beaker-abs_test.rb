require 'test_helper'

class Beaker::AbsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::BeakerAbs::Version
  end
end
