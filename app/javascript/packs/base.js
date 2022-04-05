// Listen for any input changes
$("input").on('keyup', function() {
  // Grab the base from from_base
  const from_base = $("#from_base").val();
  // Grab the base from to_base
  const to_base = $("#to_base").val();
  // Grab the input value
  const input = $("#number").val();

  // Convert the input from the from_base to the to_base
  const output = parseInt(input, from_base).toString(to_base);

  // Update the output
  $("#result").val(output);
});
