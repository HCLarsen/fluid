require "liquid"
require "./fluid/htmlable"
require "./fluid/textable"

# Fluid is a document generating system that uses Shopify's [Liquid](http://shopify.github.io/liquid/) templating language.

# **NOTE:** This shard is currently a Work in Progress for 2 reasons. First, it heavily depends on [liquid.cr](https://github.com/TechMagister/liquid.cr) which is also marked as WIP. Second, I'm still developing how the interface for the classes and mixins will work, so breaking changes should be expected. During this time, I welcome any feedback on what would be most useful to the community.

# Fluid uses mixins to parse and render Liquid templates for classes. Common types, such as `HTMLable` and `Textable` are already provided, and others can easily be created to extend the capabilities of Fluid.

# The Liquid template for a Document can either be provided as a string, or from an external file. If neither one is provided for all the required templates, a compile time error will occur.
#
# ```crystal
# require "fluid"
#
# class Greeting < Fluid::Document
#   include Fluid::Textable
#
#   @@text_template_source = "Hello {{name}}"
#
#   def initialize(@name : String)
#   end
# end
# ```
#
# OR:
#
# ```crystal
# class Greeting < Fluid::Document
#   include Fluid::Textable
#
#   @@text_template_source = File.open("src/templates/greeting.liquid.txt")
# end
# ```
#
# Multiple mixins can be used in the same class, to provide multiple output options for a single class.
#
# ```crystal
# class Greeting
#   include Fluid::Textable
#   include Fluid::HTMLable
#
#   @@text_template_source = "Hello {{name}}"
#   @@html_template_source = %(<p class="salutation">Hello {{name}}</p>)
#
#   def initialize(@name : String)
#   end
# end
#
# greeting = Greeting.new("Chris")
# greeting.to_text  #=> "Hello Chris"
# greeting.to_html  #=> "<p class=\"salutation\">Hello World!</p>"
# ```
#
# All instance variables for the class are available to the template by the same name, without the @ sign. This is how the `@name` ivar was able to be passed in where the template listed `name` in the example above. In addition, the `Context` for the template is an instance variable, allowing anything to be added to it through the lifecycle of the object. Please see the [liquid.cr](https://github.com/TechMagister/liquid.cr) repository for the allowable types for `Liquid::Any`.


# ### Rendering Other Templates
#
# Currently, Fluid doesn't allow for use of Liquid's [render](https://shopify.github.io/liquid/tags/template/#render) command. However, any Document can be included in any other Document as a partial, provided that the included Document has the right output format. This is done by initializing the included Document, and using the `Fluid::Partial` annotation. This adds a variable to the context with a name of `render_xxx` where `xxx` is the name of the Document's class. For instance, the example below will provide a `render_greeting` value to be used in the Letter template.
#
# ```crystal
# class Letter < Fluid::Document
#   include Fluid::Textable
#
#   @@text_template_source = File.open("#{__DIR__}/templates/letter.liquid.txt")
#
#   @[LiquidPlay::Partial]
#   @greeting : Greeting
# end
# ```
module Fluid
  VERSION = "0.1.0"
end
