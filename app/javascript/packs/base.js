const result = $("#result");

// Listen for any input changes
$("input").on('keyup change keydown', function() {
  // Grab the base from from_base
  const from_base = $("#from_base").val();
  // Grab the base from to_base
  const to_base = $("#to_base").val();
  // Grab the input value
  const input = $("#number").val();

  // Convert the input from the from_base to the to_base
  const output = parseInt(input, from_base).toString(to_base)

  console.debug(`Converted ${input} from base ${from_base} to base ${to_base}. Result: ${output}`);

  // If the to_base is binary, put a space every 4 chars
  if (to_base.toString() === "2") {
    // zero pad the output string until it has a multiple of 4 length
    let missing = output.length % 4 === 0 ? 0 : 4 - output.length % 4
    let newOutput = `${"0".repeat(missing)}${output}`;
    const output_spaced = newOutput.match(/.{1,4}/g).join(" ");
    console.debug("output is now " + output_spaced)
    result.val(output_spaced);
    return;
  }

  console.debug("not base 2 :(");

  // Update the output
  result.val(output);
});
