window.customViewFormatter = function(data) {
    var template = $('#serverTemplate').html()
    var view = ''
    $.each(data, function (i, row) {
        view += template.replace('%NAME%', row.name)
            .replace('%IMAGE%', row.icon)
            .replace('%ID%', row.server_id)
            .replace('%DATE%', row.created)
            .replace('%FEATURES%', row.features)
            .replace('%STATUS_ICON%', row.status_icon + " ")
            .replace('%PERMISSIONS%', row.perms)
            .replace('%OWNER%', row.owner);
    })

    return `<div class="row mx-0">${view}</div>`
}

$(document).ready(function() {
    $("img").hover(function() {
        // Pluck the image
        /** @type {String} */
        let url = $(this).attr('src');
        // Replace png with gif, if possible
        if (url.split("/").pop().startsWith("a_")) {
            $(this).attr('src', url.replace(".png", ".gif"));
        }
    }, function() {
        // Pluck the image
        /** @type {String} */
            // Replace gif with png
        let url = $(this).attr('src');
        $(this).attr('src', url.replace(".gif", ".png"));
    });

    // Enable tooltips
    window.initializeTooltips();
});