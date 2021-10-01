import ClipboardJS from 'clipboard'

let clipboard = new ClipboardJS('#copy');
let copyButton = $("#copy");
clipboard.on('success', function (e) {
    copyButton.html("Copied!");
    copyButton.attr('class', 'btn btn-success');
    copyButton.prop("disabled", true);
    setTimeout(function() {
        copyButton.prop("disabled", false);
        copyButton.attr('class', 'btn btn-primary');
        copyButton.html("Copy");
    }, 2000);
})
clipboard.on('error', function (e) {
    document.getElementById('copy').innerHTML = 'Copy Errored :(';
})
$("#backButton").on("click", function() {
    $(this).attr('disabled', true);
    $(this).html('<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>')
});