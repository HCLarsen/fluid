# Fluid

Fluid is a document generating system that uses Shopify's [Liquid](http://shopify.github.io/liquid/) templating language.

**NOTE:** This shard is currently a Work in Progress for 2 reasons. First, it heavily depends on [liquid.cr](https://github.com/TechMagister/liquid.cr) which is also marked as WIP. Second, I'm still developing how the interface for the classes and mixins will work, so breakign changes should be expected. During this time, I welcome any feedback on what would be most useful to the community.

The abstract `Document` class provides the basis for this functionality. From there, a document can make use of multiple Liquid templates to provide outputs in various formats.

Mixins can be used to simplify the process of outputting in multiple formats. Mixins for common formats, such as text and HTML, are provided. Other mixins can easily be developed based on these examples.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     fluid:
       github: HCLarsen/fluid
   ```

2. Run `shards install`

## Usage

```crystal
require "fluid"
```

The Liquid template for a Document can either be provided as a string, or from an external file. If neither one is provided for all the required templates, a compile time error will occur.

```crystal
class Greeting < Fluid::Document
  include Fluid::Textable

  @@text_template_source = "Hello {{name}}"

  def initialize(@name : String)
  end
end
```

OR:

```crystal
class Greeting < Fluid::Document
  include Fluid::Textable

  @@text_template_source = File.open("src/templates/greeting.liquid.txt")
end
```

Mixins such as `Fluid::Textable` and `Fluid::HTMLable` automatically provide the basic variables and methods needed to generate and output the document type required. They can also be used together, so that one document can have multiple outputs.

```crystal
class Greeting < Fluid::Document
  include Fluid::Textable
  include Fluid::HTMLable

  @@text_template_source = "Hello {{name}}"
  @@html_template_source = "<h2>Hello {{name}}</h2>"

  def initialize(@name : String)
  end
end

greeting = Greeting.new("Chris")
greeting.to_text  #=> "Hello Chris"
greeting.to_html  #=> "<h2>Hello Chris</h2>"
```

All instance variables for the class are available to the template by the same name, without the @ sign. This is how the `@name` ivar was able to be passed in where the template listed `name` in the example above. In addition, the `Context` for the template is an instance variable, allowing the class to add any value to it, including method outputs. Please see the [liquid.cr](https://github.com/TechMagister/liquid.cr) repository for the allowable types for `Liquid::Any`.

### Rendering Other Templates

Currently, Fluid doesn't allow for use of Liquid's [render](https://shopify.github.io/liquid/tags/template/#render) command. However, any Document can be included in any other Document as a partial, provided that the included Document has the right output format. This is done by initializing the included Document, and using the `Fluid::Partial` annotation. This adds a variable to the context with a name of `render_xxx` where `xxx` is the name of the Document's class. For instance, the example below will provide a `render_greeting` value to be used in the Letter template.

```crystal
class Letter < Fluid::Document
  include Fluid::Textable

  @@text_template_source = File.open("#{__DIR__}/templates/letter.liquid.txt")

  @[LiquidPlay::Partial]
  @greeting : Greeting
end
```

## Development

All features must be fully tested using the `minitest.cr` library.

## Contributing

1. Fork it (<https://github.com/HCLarsen/fluid/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Larsen](https://github.com/HCLarsen) - creator and maintainer
