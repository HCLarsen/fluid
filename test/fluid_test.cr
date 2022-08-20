require "minitest/autorun"

require "/../src/fluid/textable"
require "/../src/fluid/htmlable"

class Greeting
  include Fluid::Textable
  include Fluid::HTMLable

  @@text_template_source = "Hello {{name}}"
  @@html_template_source = %(<p class="salutation">Hello {{name}}</p>)

  def initialize(@name : String)
  end
end

class Signature
  include Fluid::Textable
  include Fluid::HTMLable

  @@text_template_source = File.open("#{__DIR__}/templates/signature.liquid.txt")
  @@html_template_source = File.open("#{__DIR__}/templates/signature.liquid.html")

  def initialize(@name : String)
  end
end

class DataRow
  include Fluid::Textable
  include Fluid::HTMLable

  @@text_template_source = "{{date_string}} - {{value}}"
  @@html_template_source = %(<p>{{date_string}} - <span class="value">{{value}}</span></p>)

  def initialize(@date : Time, @value : Int32)
  end

  def before_render
    @context.set("date_string", @date.to_s("%Y/%m/%d"))
  end
end

class Letter
  include Fluid::Textable
  include Fluid::HTMLable

  @@text_template_source = File.open("#{__DIR__}/templates/letter.liquid.txt")
  @@html_template_source = File.open("#{__DIR__}/templates/letter.liquid.html")

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

class FluidTest < Minitest::Test
  def test_generates_multiple_outputs_from_string_template
    greeting = Greeting.new("World!")

    assert_equal "Hello World!", greeting.to_text
    assert_equal %(<p class="salutation">Hello World!</p>), greeting.to_html
  end

  def test_generates_multiple_outputs_from_file_template
    signature = Signature.new("Chris Larsen")

    assert_equal "Regards,\nChris Larsen", signature.to_text
    assert_equal %(<p class="signature">Regards,</p>\n<p class="name">Chris Larsen</p>), signature.to_html
  end

  def test_before_output_hook
    data = DataRow.new(Time.local(2022, 8, 4), 16)

    assert_equal %(<p>2022/08/04 - <span class="value">16</span></p>), data.to_html
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

    lexbor = Lexbor::Parser.new(letter.to_html)

    assert_equal "Hello Chris", lexbor.css(".salutation").first.inner_text
    assert_equal "Please see the data that you requested:", lexbor.css(".paragraph").first.inner_text
    assert_equal "John Smith", lexbor.css(".name").first.inner_text

    data_rows = lexbor.css(".list-item")
    assert_equal 4, data_rows.size
    assert_equal "2022/08/04 - 16", data_rows[0].inner_text
    assert_equal "2022/08/05 - 13", data_rows[1].inner_text
    assert_equal "2022/08/06 - 22", data_rows[2].inner_text
    assert_equal "2022/08/07 - 18", data_rows[3].inner_text
  end
end
