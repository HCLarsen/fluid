require "liquid"

require "../fluid"

module Fluid::Textable
  macro included
    @context = Liquid::Context.new

    @@text_template_source : String | File
    @@text_template : Liquid::Template = Liquid::Parser.parse(@@text_template_source)
  end

  def add_ivars_to_text_context : Nil
    {% for var in @type.instance_vars %}
      {% ann = var.annotation(Fluid::Partial) %}
      {% unless ann %}
        @context.set {{var.id.stringify}}, @{{var.id}}
      {% else %}
        {% if var.type <= Array %}
          @context.set "render_{{var.id}}", @{{var.id}}.map { |e| e.to_text  }
        {% else %}
          @context.set "render_{{var.id}}", @{{var.id}}.to_text
        {% end %}
      {% end %}
    {% end %}
  end

  def before_to_text
  end

  def to_text : String
    add_ivars_to_text_context

    before_to_text

    @@text_template.render(@context).strip
  end
end
