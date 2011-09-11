// Here is our Backbone model!
$(function() {
  do_test();
});

function do_test() {
  echo("<h3>Rendering from template:</h3>");
  echo(JST['hello']({name: "Julie Kitzinger", age: "33"}));
  echo("<h3>Success!</h3>");
}

// Helper functions
function echo(html) {
  $("#messages").append(html);
};

function onerror() {
  echo("<p class='error'>Oops... an error occured.</p>");
};

