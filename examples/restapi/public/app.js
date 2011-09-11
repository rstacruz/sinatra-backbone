// Here is our Backbone model!
Book = Backbone.Model.extend({
  urlRoot: '/book'
});

$(function() {
  do_create();
});

function do_create() {
  echo("<h3>Creating a book:</h3>");

  var book = new Book;
  book.set({ title: "Darkly Dreaming Dexter", author: "Jeff Lindsay" });
  book.save({}, {
    error: onerror,
    success: function() {
      print_book(book);
      echo("<h3>Retrieving the same book:</h3>");
      do_retrieve(book);
    }
  });
}

function do_retrieve(_book) {
  var book = new Book({ id: _book.id });
  book.fetch({
    error: onerror,
    success: function() {
      print_book(book);
      do_edit_error(book);
    }
  });
}

function do_edit_error(book) {
  echo("<h3>Editing book with an error:</h3>");
  console.log("(You should see an HTTP error right about here:)");
  book.set({ author: '' });
  book.save({}, {
    success: onerror,
    error: function() {
      console.log("(...yep.)");
      echo("...yes, it occured.");
      do_edit(book);
    }
  });
}

function do_edit(book) {
  echo("<h3>Editing book:</h3>");
  book.set({ author: 'Anne Rice', title: 'The Claiming of Sleeping Beauty' });
  book.save({}, {
    error: onerror,
    success: function() {
      print_book(book);
      do_delete(book);
    }
  });
}

function do_delete(book) {
  echo("<h3>Deleting book:</h3>");
  book.destroy({
    error: onerror,
    success: function() {
      echo("Success.");
      do_verify_delete(book.id);
    }
  });
}

function do_verify_delete(id) {
  echo("<h3>Checking if book "+id+" still exists:</h3>");
  console.log("(You should see an HTTP error right about here:)");
  var book = new Book({ id: id });
  book.fetch({
    success: onerror,
    error: function() {
      console.log("(...yep.)");
      echo("No, it doesn't.");
      do_success();
    }
  });
}

function do_success() {
  echo("<h3>Success!</h3>");
}

function print_book(book) {
  echo("<dl><dt>Title:</dt><dd>"+book.get('title')+"</dd></dl>");
  echo("<dl><dt>Author:</dt><dd>"+book.get('author')+"</dd></dl>");
  echo("<dl><dt>ID:</dt><dd>"+book.get('id')+"</dd></dl>");
}

// Helper functions
function echo(html) {
  $("#messages").append(html);
};

function onerror() {
  echo("<p class='error'>Oops... an error occured.</p>");
};

