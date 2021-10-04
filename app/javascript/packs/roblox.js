$("#hideAchieved").change(function(e) {
    $(this).attr('disabled', true);
    if ($(this).is(':checked')) {
        window.location = window.location.href.replace("&achieved=false", '') + "&achieved=true";
    } else {
        window.location = window.location.href.replace("&achieved=true", '') + "&achieved=false";
    }
})