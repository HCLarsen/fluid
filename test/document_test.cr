require "minitest/autorun"

require "/../src/fluid/document"

class Greeting < Document
  @@text_template_source = "Hello {{name}}"

  def initialize(@name : String)
  end
end

class Signature < Document
  @@text_template_source = File.open("#{__DIR__}/templates/signature.liquid.txt")

  def initialize(@name : String)
  end
end

class DocumentTest < Minitest::Test
  def test_initializes_with_template_string
    greeting = Greeting.new("World!")

    assert_equal "Hello World!", greeting.to_text
  end

  def test_initializes_with_template_file
    signature = Signature.new("Chris Larsen")

    assert_equal "Regards,\nChris Larsen", signature.to_text
  end
end
