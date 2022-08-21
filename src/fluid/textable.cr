require "./common"

# The `Fluid::Textable` mixin automatically generates methods to generate text output of a report. As text documents have no special formatting, it's the simplest `Fluid` mixin.
#
# A simple example:
#
# ```
# require "fluid"
#
# class TextGreeting
#   include Fluid::Textable
#
#   @@text_template_source = "Hello {{name}}"
#
#   def initialize(@name : String)
#   end
# end
#
# greeting = TextGreeting.new("World!")
#
# greeting.to_text #=> "Hello World!"
# ```
#
# The `#to_text` returns a String generated from the Liquid template provided. The `Context` for this generation automatically includes all instance variables by their own name, without the '@' sign in front. The method also calls the `#before_render` and `#before_to_text` hooks after adding the instance variables to the context, allowing the developer to overwrite any of them, or add additional values to the context.
#
module Fluid::Textable
  macro included
    @context = Liquid::Context.new

    @@text_template_source : String | File
    @@text_template : Liquid::Template = Liquid::Parser.parse(@@text_template_source)
  end

  private def add_ivars_to_text_context : Nil
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

  # A hook that is executed during the output of any `Fluid` mixin. Unlike '#before_to_text', this hook is called during all `Fluid` mixin output methods.
  def before_render
  end

  # A hook that is executing during the `#to_text` method.
  def before_to_text
  end

  # Generates and returns the text output of the document.
  #
  # Executes 2 hooks, `#before_render` and `#before_to_text`, in that order.
  #
  def to_text : String
    add_ivars_to_text_context

    before_render
    before_to_text

    @@text_template.render(@context).strip
  end
end
