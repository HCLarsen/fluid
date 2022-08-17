require "minitest/autorun"

require "/../src/fluid/htmlable"

class HTMLGreeting
  include Fluid::HTMLable

  @@html_template_source = "<p>Hello {{name}}</p>"

  def initialize(@name : String)
  end
end

class HTMLSignature
  include Fluid::HTMLable

  @@html_template_source = File.open("#{__DIR__}/templates/signature.liquid.html")

  def initialize(@name : String)
  end
end

class HTMLDataRow
  include Fluid::HTMLable

  @@html_template_source = "<p>{{date_string}} - {{value}}</p>"

  def initialize(@date : Time, @value : Int32)
  end

  def before_to_html
    @context.set("date_string", @date.to_s("%Y/%m/%d"))
  end
end

class HTMLLetter
  include Fluid::HTMLable

  @@html_template_source = File.open("#{__DIR__}/templates/letter.liquid.html")

  @[Fluid::Partial]
  @greeting : HTMLGreeting

  @[Fluid::Partial]
  @signature : HTMLSignature

  @[Fluid::Partial]
  @data_rows : Array(HTMLDataRow)

  def initialize(@to : String, @from : String)
    @greeting = HTMLGreeting.new(@to.split[0])
    @signature = HTMLSignature.new(@from)

    @data_rows = [
      HTMLDataRow.new(Time.local(2022, 8, 4), 16),
      HTMLDataRow.new(Time.local(2022, 8, 5), 13),
      HTMLDataRow.new(Time.local(2022, 8, 6), 22),
      HTMLDataRow.new(Time.local(2022, 8, 7), 18)
    ]
  end
end

class HTMLableTest < Minitest::Test
  def test_generates_html_output_from_string_template
    greeting = HTMLGreeting.new("World!")

    assert_equal "<p>Hello World!</p>", greeting.to_html
  end

  def test_generates_text_output_from_file_template
    signature = HTMLSignature.new("Chris Larsen")

    assert_equal "<p>Regards,</p>\n<p>Chris Larsen</p>", signature.to_html
  end

  def test_before_output_hook
    data = HTMLDataRow.new(Time.local(2022, 8, 4), 16)

    assert_equal "<p>2022/08/04 - 16</p>", data.to_html
  end

  def test_includes_other_documents
    letter = HTMLLetter.new("Chris Larsen", "John Smith")
    text = letter.to_html

    assert_equal "<p>Hello Chris</p>,", text.lines[0]
    assert_equal "<p>Please see the data that you requested:</p>", text.lines[2]
    assert_equal "<li><p>2022/08/04 - 16</p></li>", text.lines[5]
    assert_equal "<li><p>2022/08/05 - 13</p></li>", text.lines[6]
    assert_equal "<li><p>2022/08/06 - 22</p></li>", text.lines[7]
    assert_equal "<li><p>2022/08/07 - 18</p></li>", text.lines[8]
    assert_equal "<p>John Smith</p>", text.lines.last
  end
end
