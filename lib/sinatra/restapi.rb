require 'json'

# ## Sinatra::RestAPI [module]
# A plugin for providing rest API to models. Great for Backbone.js.
#
# To use this, simply `register` it to your Sinatra Application.  You can then
# use `rest_create` and `rest_resource` to create your routes.
#
#     require 'sinatra/restapi'
#
#     class App < Sinatra::Base
#       register Sinatra::RestAPI
#     end
#
# ### RestAPI example
# Here's a simple example of how to use Backbone models with RestAPI.
# Also see the [example application][ex] included in the gem.
#
# [ex]: https://github.com/rstacruz/sinatra-backbone/tree/master/examples/restapi
#
# #### Model setup
# Let's say you have a `Book` model in your application. Let's use [Sequel][sq]
# for this example, but feel free to use any other ORM that is
# ActiveModel-compatible.
#
# You will need to define `to_hash` in your model.
#
#     db = Sequel.connect(...)
#
#     db.create_table :books do
#       primary_key :id
#       String :title
#       String :author
#     end
#
#     class Book < Sequel::Model
#       # ...
#       def to_hash
#         { :title => title, :author => author, :id => id }
#       end
#     end
#
# [sq]: http://sequel.rubyforge.org
#
# #### Sinatra
# To provide some routes for Backbone models, use `rest_resource` and
# `rest_create`:
#
#     require 'sinatra/restapi'
#
#     class App < Sinatra::Base
#       register Sinatra::RestAPI
#
#       rest_create '/book' do
#         Book.new
#       end
#
#       rest_resource '/book/:id' do |id|
#         Book.find(:id => id)
#       end
#     end
#
# #### JavaScript
# In your JavaScript files, let's make a corresponding model.
#
#     Book = Backbone.Model.extend({
#       urlRoot: '/book'
#     });
#
# Now you may create a new book through your JavaScript:
#
#     book = new Book;
#     book.set({ title: "Darkly Dreaming Dexter", author: "Jeff Lindsay" });
#     book.save();
#
#     // In Ruby, equivalent to:
#     // book = Book.new
#     // book.title  = "Darkly Dreaming Dexter"
#     // book.author = "Jeff Lindsay"
#     // book.save
#
# Or you may retrieve new items. Note that in this example, since we defined
# `urlRoot()` but not `url()`, the model URL with default to `/[urlRoot]/[id]`.
#
#     book = new Book({ id: 1 });
#     book.fetch();
#
#     // In Ruby, equivalent to:
#     // Book.find(:id => 1)
#
# Deletes will work just like how you would expect it:
#
#     book.destroy();
#
module Sinatra::RestAPI
  def self.registered(app)
    app.helpers Helpers
  end

  # ### rest_create(path, &block) [method]
  # Creates a *create* route on the given `path`.
  #
  # This creates a `POST` route in */documents* that accepts JSON data.
  # This route will return the created object as JSON.
  #
  # When getting a request, it does the following:
  # 
  #  * A new object is created by *yielding* the block you give. (Let's
  #    call it `object`.)
  #
  #  * For each of the attributes, it uses the `attrib_name=` method in
  #    your record. For instance, for an attrib like `title`, it wil lbe
  #    calling `object.title = "hello"`.
  #
  #  * if `object.valid?` returns false, it returns an error 400.
  #
  #  * `object.save` will then be called.
  #
  #  * `object`'s contents will then be returned to the client as JSON.
  #
  # See the example.
  #
  #     class App < Sinatra::Base
  #       rest_create "/documents" do
  #         Document.new
  #       end
  #     end
  #
  def rest_create(path, options={}, &blk)
    # Create
    post path do
      @object = yield
      rest_params.each { |k, v| @object.send :"#{k}=", v }

      return 400, @object.errors.to_json  unless @object.valid?

      @object.save
      rest_respond @object.to_hash
    end
  end

  # ### rest_resource(path, &block) [method]
  # Creates a *get*, *edit* and *delete* route on the given `path`.
  #
  # The block given will be yielded to do a record lookup. If the block returns
  # `nil`, RestAPI will return a *404*.
  #
  # In the example, it creates routes for `/document/:id` to accept HTTP *GET*
  # (for object retrieval), *PUT* (for editing), and *DELETE* (for destroying).
  #
  # Your model needs to implement the following methods:
  #
  #    * `save` (called on edit)
  #    * `destroy` (called on delete)
  #    * `<attrib_name_here>=` (called for each of the attributes on edit)
  #
  # If you only want to create routes for only one or two of the actions, you
  # may individually use:
  #
  #    * `rest_get`
  #    * `rest_edit`
  #    * `rest_delete`
  #
  # All the methods above take the same arguments as `rest_resource`.
  #
  #     class App < Sinatra::Base
  #       rest_resource "/document/:id" do |id|
  #         Document.find(:id => id)
  #       end
  #     end
  #
  def rest_resource(path, options={}, &blk)
    rest_get    path, options, &blk
    rest_edit   path, options, &blk
    rest_delete path, options, &blk
  end

  # ### rest_get(path, &block) [method]
  # This is the same as `rest_resource`, but only handles *GET* requests.
  #
  def rest_get(path, options={}, &blk)
    get path do |*args|
      @object = yield(*args) or pass
      rest_respond @object
    end
  end

  # ### rest_edit(path, &block) [method]
  # This is the same as `rest_resource`, but only handles *PUT*/*POST* (edit)
  # requests.
  #
  def rest_edit(path, options={}, &blk)
    callback = Proc.new { |*args|
      @object = yield(*args) or pass
      rest_params.each { |k, v| @object.send :"#{k}=", v  unless k == 'id' }

      return 400, @object.errors.to_json  unless @object.valid?

      @object.save
      rest_respond @object
    }

    # Make it work with `Backbone.emulateHTTP` on.
    put  path, &callback
    post path, &callback
  end

  # ### rest_delete(path, &block) [method]
  # This is the same as `rest_resource`, but only handles *DELETE* (edit)
  # requests. This uses `Model#destroy` on your model.
  #
  def rest_delete(path, options={}, &blk)
    delete path do |*args|
      @object = yield(*args) or pass
      @object.destroy
      rest_respond :result => :success
    end
  end

  # ### JSON conversion
  #
  # The *create* and *get* routes all need to return objects as JSON. RestAPI
  # attempts to convert your model instances to JSON by first trying
  # `object.to_json` on it, then trying `object.to_hash.to_json`.
  #
  # It's recommended you implement `#to_hash` in your models.

  # ### Helper methods
  # There are some helper methods that are used internally be `RestAPI`,
  # but you can use them too if you need them.
  #
  module Helpers
    # #### rest_respond(object)
    # Responds with a request with the given `object`.
    #
    # This will convert that object to either JSON or XML as needed, depending
    # on the client's preferred type (dictated by the HTTP *Accepts* header).
    #
    def rest_respond(obj)
      case request.preferred_type('*/json', '*/xml')
      when '*/json'
        content_type :json
        rest_convert_to_json obj

      else
        pass
      end
    end

    # #### rest_params
    # Returns the object from the request.
    #
    # If the client sent `application/json` (or `text/json`) as the content
    # type, it tries to parse the request body as JSON.
    #
    # If the client sent a standard URL-encoded POST with a `model` key
    # (happens when Backbone uses `Backbone.emulateJSON = true`), it tries
    # to parse its value as JSON.
    #
    # Otherwise, the params will be returned as is.
    #
    def rest_params
      if File.fnmatch('*/json', request.content_type)
        JSON.parse request.body.read

      elsif params['model']
        # Account for Backbone.emulateJSON.
        JSON.parse params['model']

      else
        params
      end
    end

    def rest_convert_to_json(obj)
      # Convert to JSON. This will almost always work as the JSON lib adds
      # #to_json to everything.
      json = obj.to_json

      # The default to_json of objects is to JSONify the #to_s of an object,
      # which defaults to #inspect. We don't want that.
      return json  unless json[0..2] == '"#<'

      # Let's hope they redefined to_hash.
      return obj.to_hash.to_json  if obj.respond_to?(:to_hash)

      raise "Can't convert object to JSON"
    end
  end
end
