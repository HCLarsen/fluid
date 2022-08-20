require "liquid"

require "../fluid"

module Fluid::HTMLable
  HTML_DOC_TEMPLATE = <<-STRING
  <!DOCTYPE html>
  <html>
  <head>
    {{html_head}}
  </head>
  <body>
    {{html_body}}
  </body>
  </html>
  STRING

  @@css : String?

  macro included
    @context = Liquid::Context.new

    @@html_template_source : String | File
    @@html_template : Liquid::Template = Liquid::Parser.parse(@@html_template_source)

    def self.css : String?
      @@css
    end
  end

  def add_ivars_to_html_context : Nil
    {% for var in @type.instance_vars %}
      {% ann = var.annotation(Fluid::Partial) %}
      {% unless ann %}
        @context.set {{var.id.stringify}}, @{{var.id}}
      {% else %}
        {% if var.type <= Array %}
          @context.set "render_{{var.id}}", @{{var.id}}.map { |e| e.to_html  }
        {% else %}
          @context.set "render_{{var.id}}", @{{var.id}}.to_html
        {% end %}
      {% end %}
    {% end %}
  end

  def css : String?
    @@css
  end

  def full_css : String
    style = ""
    {% for var in @type.instance_vars %}
      {% ann = var.annotation(Fluid::Partial) %}
      {% if ann %}
        {% if var.type <= Array %}
          if partial_css = @{{var.id}}.first.class.css
            style += "\n" + partial_css
          end
        {% else %}
          if partial_css = {{var.type.id}}.css
            style += "\n" + partial_css
          end
        {% end %}
      {% end %}
    {% end %}

    if local_css = @@css
      style += "\n" + local_css
    end

    style
  end

  def html_head(minify : Bool) : String
    style = full_css

    if minify
      style = minify_css(style)
    end

    <<-HEREDOC
    <style>
      #{style}
    </style>
    HEREDOC
  end

  def before_render
  end

  def before_to_html
  end

  def to_html : String
    add_ivars_to_html_context

    before_render
    before_to_html

    @@html_template.render(@context).strip
  end

  def to_html_doc(minify = true) : String
    context = Liquid::Context.new
    context.set("html_body", to_html)
    context.set("html_head", html_head(minify))

    doc_template = Liquid::Parser.parse(HTML_DOC_TEMPLATE)

    html = doc_template.render(context).strip

    if minify
      return minify_html(html)
    else
      return html
    end
  end

  private def minify_html(html : String) : String
    html.gsub(/\n\s*/m, "")
  end

  private def minify_css(css : String) : String
    css.gsub(/\n\s*/m, "").gsub(/:\s/, ":").gsub(/\s{/, "{")
  end
end
