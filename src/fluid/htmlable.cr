require "./common"

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

    # Returns the unminified CSS for this class.
    def self.css : String?
      @@css
    end
  end

  private def add_ivars_to_html_context : Nil
    {% for var in @type.instance_vars %}
      {% ann = var.annotation(Fluid::Context) %}
      {% if !ann %}
        @context.set {{var.id.stringify}}, @{{var.id}}
      {% elsif ann[:partial] == true %}
        {% if var.type <= Array %}
          @context.set "render_{{var.id}}", @{{var.id}}.map { |e| e.to_html  }
        {% else %}
          @context.set "render_{{var.id}}", @{{var.id}}.to_html
        {% end %}
      {% end %}
    {% end %}
  end

  # Returns the unminified CSS for this document.
  def css : String?
    @@css
  end

  # Returns the CSS for this document and all included partials.
  def full_css : String
    style = ""
    {% for var in @type.instance_vars %}
      {% ann = var.annotation(Fluid::Context) %}
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

  # Returns the contents of the <head> element for the html output.
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

  # A hook that is executed during the output of any `Fluid` mixin. Unlike '#before_to_text', this hook is called during all `Fluid` mixin output methods.
  def before_render
  end

  # A hook that is executing during the `#to_html` method.
  def before_to_html
  end

  # Generates and returns the html output of the document.
  #
  # Executes 2 hooks, `#before_render` and `#before_to_html`, in that order.
  #
  def to_html : String
    add_ivars_to_html_context

    before_render
    before_to_html

    @@html_template.render(@context).strip
  end

  # Generates and returns a complete HTML document with the output from `#to_html` forming the <body> element.
  #
  # For example:
  # ```
  # greeting.to_html      #=> %(<p class="salutation">Hello {{name}}</p>)
  # greeting.to_html_doc  #=> %(<!DOCTYPE html><html><head><style>.salutation{font-style:italic;}</style></head><body><p class="salutation">Hello {{name}}</p></body></html>)
  #
  # ```
  #
  # Like `#to_html`, this method executes the `#before_render` and `#before_to_html` hooks, in that order.
  #
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
