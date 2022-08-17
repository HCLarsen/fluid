require "liquid"

module Fluid::HTMLable
  macro included
    @context = Liquid::Context.new

    @@html_template_source : String | File
    @@html_template : Liquid::Template = Liquid::Parser.parse(@@html_template_source)
  end

  def set_ivars_in_context : Nil
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

  def before_to_html
  end

  def to_html : String
    set_ivars_in_context

    before_to_html

    @@html_template.render(@context).strip
  end
end
