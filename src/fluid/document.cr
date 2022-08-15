require "liquid"

abstract class Document
  @context = Liquid::Context.new

  macro inherited
    @@text_template_source : String | File
    @@text_template : Liquid::Template = Liquid::Parser.parse(@@text_template_source)
  end

  def add_ivars_to_context
    {% for var in @type.instance_vars %}
      @context.set {{var.id.stringify}}, @{{var.id}}
    {% end %}
  end

  def to_text : String
    add_ivars_to_context

    @@text_template.render(@context).strip
  end
end
