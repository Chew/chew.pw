import ClipboardJS from 'clipboard'

$("#apiRandomForm").on('submit', function (e) {
    e.preventDefault();

    let form = $(this);

    $.get("/api/random", form.serializeArray(), function (result) {
        $("#result").text(result.response);
        $("#copy").attr('data-clipboard-text', result.response);
        form.find('input[type=submit]').attr('disabled', false)
    });
});

let clipboard = new ClipboardJS('#copy');
let copyButton = $("#copy");
clipboard.on('success', function (e) {
    copyButton.html("Copied!");
    copyButton.attr('class', 'btn btn-success');
    setTimeout(function() {
        copyButton.html("Copy");
        copyButton.attr('class', 'btn btn-primary');
        initializeTooltips();
    }, 2000);
})
clipboard.on('error', function (e) {
    document.getElementById('copy').innerHTML = 'Copy Errored :(';
})

initializeTooltips();