require "minitest/autorun"

require "liquid"

require "/../src/fluid/textable"

class Greeting
  include Fluid::Textable

  @@text_template_source = "Hello {{name}}"

  def initialize(@name : String)
  end
end

class Signature
  include Fluid::Textable

  @@text_template_source = File.open("#{__DIR__}/templates/signature.liquid.txt")

  def initialize(@name : String)
  end
end

class DataRow
  include Fluid::Textable

  @@text_template_source = "{{date_string}} - {{value}}"

  def initialize(@date : Time, @value : Int32)
  end

  def before_to_text
    @context.set("date_string", @date.to_s("%Y/%m/%d"))
  end
end

class Letter
  include Fluid::Textable

  @@text_template_source = File.open("#{__DIR__}/templates/letter.liquid.txt")

  @[Fluid::Partial]
  @greeting : Greeting

  @[Fluid::Partial]
  @signature : Signature

  @[Fluid::Partial]
  @data_rows : Array(DataRow)

  def initialize(@to : String, @from : String)
    @greeting = Greeting.new(@to.split[0])
    @signature = Signature.new(@from)

    @data_rows = [
      DataRow.new(Time.local(2022, 8, 4), 16),
      DataRow.new(Time.local(2022, 8, 5), 13),
      DataRow.new(Time.local(2022, 8, 6), 22),
      DataRow.new(Time.local(2022, 8, 7), 18)
    ]
  end
end

class TextableTest < Minitest::Test
  def test_generates_text_output_from_string_template
    greeting = Greeting.new("World!")

    assert_equal "Hello World!", greeting.to_text
  end

  def test_generates_text_output_from_file_template
    signature = Signature.new("Chris Larsen")

    assert_equal "Regards,\nChris Larsen", signature.to_text
  end

  def test_before_output_hook
    data = DataRow.new(Time.local(2022, 8, 4), 16)

    assert_equal "2022/08/04 - 16", data.to_text
  end

  def test_includes_other_documents
    letter = Letter.new("Chris Larsen", "John Smith")
    text = letter.to_text

    assert_equal "Hello Chris,", text.lines[0]
    assert_equal "Please see the data that you requested:", text.lines[2]
    assert_equal "2022/08/04 - 16", text.lines[4]
    assert_equal "2022/08/05 - 13", text.lines[5]
    assert_equal "2022/08/06 - 22", text.lines[6]
    assert_equal "2022/08/07 - 18", text.lines[7]
    assert_equal "John Smith", text.lines.last
  end
end
