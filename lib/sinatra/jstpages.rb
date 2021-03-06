# ## JstPages [module]
# A Sinatra plugin that adds support for JST (JavaScript Server Templates).
# See [JstPages example][jstx] for a full example application.
#
# ### Basic usage
# Register the `Sinatra::JstPages` plugin in your application, and use
# `serve_jst`.  This example serves all JST files found in `/views/**/*.jst.*`
# (where `/views` is your views directory as defined in Sinatra's
# `settings.views`) as `http://localhost:4567/jst.js`.
#
#     require 'sinatra/jstpages'
#
#     class App < Sinatra::Base
#       register Sinatra::JstPages
#       serve_jst '/jst.js'
#     end
#
# You will need to link to the JST route in your layout. Make a `<script>` tag
# where the `src='...'` attribute is the same path you provide to `serve_jst`.
#
#     <script type='text/javascript' src='/jst.js'></script>
#
# So, if you have a JST view placed in `views/editor/edit.jst.tpl`:
#
#     # views/editor/edit.jst.tpl
#     <h1>Edit <%= name %></h1>
#     <form>
#       <button>Save</button>
#     </form>
#
# Now in your browser you may invoke `JST['templatename']`:
#
#     // Renders the editor/edit template
#     JST['editor/edit']();
#
#     // Renders the editor/edit template with template parameters
#     JST['editor/edit']({name: 'Item Name'});
#
# #### Using Sinatra-AssetPack?
#
# __TIP:__ If you're using the [sinatra-assetpack][sap] gem, just add `/jst.js`
# to a package.  (If you're not using Sinatra AssetPack yet, you probably
# should.)
#
# [sap]: http://ricostacruz.com/sinatra-assetpack
#
# ### Supported templates
#
# __[Jade][jade]__ (`.jst.jade`) -- Jade templates. This requires
# [jade.js][jade]. For older browsers, you will also need [json2.js][json2],
# and an implementation of [String.prototype.trim][trim].
#
#     # views/editor/edit.jst.jade
#     h1= "Edit "+name
#       form
#         button Save
#
# __[Underscore templates][under_tpl]__ (`.jst.tpl`) -- Simple templates by
# underscore. This requires [underscore.js][under], which Backbone also
# requires.
#
#     # views/editor/edit.jst.tpl
#     <h1>Edit <%= name %></h1>
#     <form>
#       <button>Save</button>
#     </form>
#
# __[Haml.js][haml]__ (`.jst.haml`) -- A JavaScript implementation of Haml.
# Requires [haml.js][haml].
#
#     # views/editor/edit.jst.haml
#     %h1= "Edit "+name
#       %form
#         %button Save
#
# __[Eco][eco]__ (`.jst.eco`) -- Embedded CoffeeScript templates. Requires
# [eco.js][eco] and [coffee-script.js][cs].
#
#     # views/editor/edit.jst.eco
#     <h1>Edit <%= name %></h1>
#     <form>
#       <button>Save</button>
#     </form>
#
# You can add support for more templates by subclassing the `Engine` class.
#
# [jade]: http://github.com/visionmedia/jade
# [json2]: https://github.com/douglascrockford/JSON-js
# [trim]: http://snippets.dzone.com/posts/show/701
# [under_tpl]: http://documentcloud.github.com/underscore/#template
# [under]: http://documentcloud.github.com/underscore
# [haml]: https://github.com/creationix/haml-js
# [eco]: https://github.com/sstephenson/eco
# [cs]: http://coffeescript.org
# [jstx]: https://github.com/rstacruz/sinatra-backbone/tree/master/examples/jstpages
#
module Sinatra
  module JstPages
    def self.registered(app)
      app.extend ClassMethods
      app.helpers Helpers
    end

    # Returns a hash to determine which engine is mapped onto a given extension.
    def self.mappings
      @mappings ||= Hash.new
    end

    def self.register(ext, engine)
      mappings[ext] = engine
    end

    module Helpers
      # Returns a list of JST files.
      def jst_files(options = {})
        # Tuples of [ name, Engine instance ]
        root = options[:root] || settings.views
        tuples = Dir.chdir(root) {
          Dir["**/*.jst*"].map { |fn|
            name   = fn.match(%r{^(.*)\.jst})[1]
            ext    = fn.match(%r{\.([^\.]*)$})[1]
            engine = JstPages.mappings[ext]

            [ name, engine.new(name, File.join(root, fn)) ] if engine
          }.compact
        }

        Hash[*tuples.flatten]
      end
    end

    module ClassMethods
      # ### serve_jst(path, [options]) [class method]
      # Serves JST files in given `path`.
      #
      def serve_jst(path, options={})
        get path do
          content_type :js
          jsts = jst_files(options).map do |(name, engine)|
            engine.compile!
          end

          %{
            (function(){
              var c = {};
              if (!window.JST) window.JST = {};
              #{jsts.join("\n  ")}
            })();
          }.strip.gsub(/^ {12}/, '')
        end
      end
    end
  end
end


# ## JstPages::Engine [class]
# A template engine.
#
# #### Adding support for new template engines
# You will need to subclass `Engine`, override at least the `function` method,
# then use `JstPages.register`.
#
# This example will register `.jst.my` files to a new engine that uses
# `My.compile`.
#
#     module Sinatra::JstPages
#       class MyEngine < Engine
#         def compile!() "My.compile(#{contents.inspect})"; end
#       end
#
#       register 'my', MyEngine
#     end
#
module Sinatra::JstPages
  class Engine
    # ### name [attribute]
    # The name of the template.
    attr_reader :name

    # ### file [attribute]
    # The string path of the template file.
    attr_reader :file

    def initialize(name, file)
      @name = name
      @file = file
    end

    # ### contents [method]
    # Returns the contents of the template file as a string.
    def contents
      File.read(@file)
    end

    def wrap_jst(name)
      compiled_contents = contents
      compiled_contents = yield if block_given?

      <<JS.strip.gsub(/^ {12}/, '')
JST[#{name.inspect}] = function() {
    if (!c[#{name.inspect}]) c[#{name.inspect}] = (#{compiled_contents});
    return c[#{name.inspect}].apply(this, arguments);
  };
JS
    end

    # ### function [method]
    # The JavaScript function to invoke on the precompile'd object.
    #
    # What this returns should, in JavaScript, return a function that can be
    # called with an object hash of the params to be passed onto the template.
    def compile!
      wrap_jst(name) do
        "_.template(#{contents.inspect})"
      end
    end
  end

  class HamlEngine < Engine
    def compile!
      wrap_jst(name) do
        "Haml(#{contents.inspect})";
      end
    end
  end

  class JadeEngine < Engine
    def compile!
      wrap_jst(name) do
        "require('jade').compile(#{contents.inspect})"
      end
    end
  end

  class EcoEngine < Engine
    def compile!
      wrap_jst(name) do
        "function() { var a = arguments.slice(); a.unshift(#{contents.inspect}); return eco.compile.apply(eco, a); }"
      end
    end
  end

  class HamlCoffeeEngine < Engine
    def compile!
      HamlCoffeeAssets.config.context = false
      HamlCoffeeAssets::Compiler.compile(name, contents, true).
        match(/^  window.JST(.*)\n  };$/m)[0].gsub(/^  window.JST/, 'JST')
    end
  end

  register 'tpl', Engine
  register 'jst', Engine
  register 'jade', JadeEngine
  register 'haml', HamlEngine
  register 'eco', EcoEngine

  if defined?(HamlCoffeeAssets)
    register 'hamlc', HamlCoffeeEngine
  end
end
