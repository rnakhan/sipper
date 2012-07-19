require 'base_test_case'
require 'util/expectation_parser'

class TestExpectationParser < BaseTestCase

  def setup
    super
    @e = SipperUtil::ExpectationParser.new
  end
  
  def test_simple
    @e.parse(["< INVITE", "> 100", "> 200"])
    assert(@e.match("< INVITE")[0])
    assert(!@e.match("< INVITE")[0]) # only one
    assert(!@e.match("> 180")[0]) # only 100
    assert(@e.match("> 100")[0])
    assert(!@e.match("> 100")[0])
    assert(@e.match("> 200")[0])
    assert(!@e.match("> 200")[0])
  end
  
  def test_alteration
    @e.parse(["< INVITE|SUBSCRIBE", "> 1xx", "> 2xx"])
    assert(@e.match("< SUBSCRIBE")[0])
    assert(!@e.match("< INVITE")[0]) # only one
    assert(@e.match("> 180")[0])
    assert(!@e.match("> 180")[0])  # only one 1xx
    assert(@e.match("> 202")[0])
    assert(!@e.match("> 202")[0]) # only one 2xx
  end
  
  def test_repetition1
    @e.parse(["< INVITE|SUBSCRIBE {2,2}", "> 1xx {3,3}", "> 2xx"])
    assert(@e.match("< SUBSCRIBE")[0])
    assert(@e.match("< INVITE")[0])
    assert(!@e.match("< SUBSCRIBE")[0]) # exactly 2
    assert(@e.match("> 100")[0])
    assert(@e.match("> 180")[0])
    assert(!@e.match("> 200")[0]) # not yet
    assert(@e.match("> 180")[0])  # exactly 3
    assert(@e.match("> 202")[0])  
  end
  
  def test_repetition2
    @e.parse(["< INVITE|SUBSCRIBE|NOTIFY {3,}", "> 1xx {1,}", "> 2xx {,2}"])
    assert(@e.match("< SUBSCRIBE")[0])
    assert(@e.match("< INVITE")[0])
    assert(@e.match("< NOTIFY")[0])
    assert(@e.match("< INVITE")[0]) # greater than 3
    assert(@e.match("> 100")[0])
    assert(@e.match("> 180")[0])
    assert(@e.match("> 100")[0])
    assert(@e.match("> 180")[0])
    assert(@e.match("> 202")[0])
    assert(!@e.match("> 302")[0])
  end
  
  def test_optionality1
    @e.parse(["> INVITE", "< 100 {0,}", "< 200"])
    assert(@e.match("> INVITE")[0])
    assert(@e.match("< 200")[0])
  end
  
  def test_optionality2
    @e.parse(["> INVITE", "< 100 {0,}", "> INVITE"])
    assert(@e.match("> INVITE")[0])
    assert(!@e.match("> INVITE")[0]) # does not match
  end 
  
  def test_optionality3
    @e.parse(["> INVITE", "< 100 {0,}", "< 200 {0,}", "> SUBSCRIBE"])
    assert(@e.match("> INVITE")[0])
    assert(@e.match("> SUBSCRIBE")[0])
  end
  
end
