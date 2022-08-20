require "minitest/autorun"

require "lexbor"

require "/../src/fluid/htmlable"

class HTMLGreeting
  include Fluid::HTMLable

  @@html_template_source = %(<p class="salutation">Hello {{name}}</p>)

  def initialize(@name : String)
  end
end

class HTMLSignature
  include Fluid::HTMLable

  @@css = <<-HEREDOC
  .name {
    font-style: italic;
  }
  HEREDOC

  @@html_template_source = File.open("#{__DIR__}/templates/signature.liquid.html")

  def initialize(@name : String)
  end
end

class HTMLDataRow
  include Fluid::HTMLable

  @@html_template_source = %(<p>{{date_string}} - <span class="value">{{value}}</span></p>)

  @@css = <<-HEREDOC
  .value {
    font-style: italic;
  }
  HEREDOC

  def initialize(@date : Time, @value : Int32)
  end

  def before_to_html
    @context.set("date_string", @date.to_s("%Y/%m/%d"))
  end
end

class HTMLLetter
  include Fluid::HTMLable

  @@html_template_source = File.open("#{__DIR__}/templates/letter.liquid.html")

  @@css = <<-HEREDOC
  ul.list {
    list-style: none;
  }
  HEREDOC

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

    assert_equal %(<p class="salutation">Hello World!</p>), greeting.to_html
  end

  def test_generates_text_output_from_file_template
    signature = HTMLSignature.new("Chris Larsen")

    assert_equal %(<p class="signature">Regards,</p>\n<p class="name">Chris Larsen</p>), signature.to_html
  end

  def test_before_output_hook
    data = HTMLDataRow.new(Time.local(2022, 8, 4), 16)

    assert_equal %(<p>2022/08/04 - <span class="value">16</span></p>), data.to_html
  end

  def test_includes_other_documents
    letter = HTMLLetter.new("Chris Larsen", "John Smith")

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

  def test_exports_full_html_doc
    letter = HTMLLetter.new("Chris Larsen", "John Smith")
    html = letter.to_html
    doc = letter.to_html_doc

    refute html.starts_with?("<!DOCTYPE html><html>")
    assert doc.starts_with?("<!DOCTYPE html><html>")

    refute html.ends_with?("</body></html>")
    assert doc.ends_with?("</body></html>")
  end

  def test_exports_unminified_html
    letter = HTMLLetter.new("Chris Larsen", "John Smith")
    unminified = letter.to_html_doc(false)

    assert unminified.starts_with?("<!DOCTYPE html>\n<html>")
    assert unminified.ends_with?("</body>\n</html>")
  end

  def test_exports_raw_css
    signature = HTMLSignature.new("Chris Larsen")

    expected = <<-HEREDOC
    .name {
      font-style: italic;
    }
    HEREDOC

    assert_equal expected, signature.css
  end

  def test_includes_css_in_html_head
    letter = HTMLLetter.new("Chris Larsen", "John Smith")

    lexbor = Lexbor::Parser.new(letter.to_html_doc)
    head = lexbor.css("head").first

    assert_includes head.inner_text, "ul.list{list-style:none;}"
  end

  def test_includes_css_of_partials
    letter = HTMLLetter.new("Chris Larsen", "John Smith")

    lexbor = Lexbor::Parser.new(letter.to_html_doc)
    head = lexbor.css("head").first

    assert_includes head.inner_text, ".name{font-style:italic;}"
    assert_includes head.inner_text, ".value{font-style:italic;}"
  end

  def test_parent_css_is_after_partial_css
    letter = HTMLLetter.new("Chris Larsen", "John Smith")

    lexbor = Lexbor::Parser.new(letter.to_html_doc)
    head = lexbor.css("head").first.inner_text

    assert head.index("ul.list{list-style:none;}").not_nil! > head.index(".value{font-style:italic;}").not_nil!
  end
end
