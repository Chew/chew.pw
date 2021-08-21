jQuery.fn.outerHtml = function(newHtml){
    // if it's passed, return the replacement outer HTML
    // otherwise, get the outerHTML and return it
    // IE, Chrome, Safari & FF 11+ will comply with first method
    // all others (FF < 11) will use fall-back for cloning
    return newHtml ? this.replaceWith(newHtml) : ( this[0].outerHTML || jQuery('<div>').append(clone(this)).remove().html() );
};

let initializeAllLinks = function() {
    $("a").on("click", function(e) {
        let obj = $(this);
        console.log(obj);
        let href = obj.prop('href');
        if (!href.includes("build")) {
            return;
        }
        obj.outerHtml(`<span id="${obj.prop('id')}">Loading...</span>`)
    });
}

// Select all links
$(document).ready(function() {
    initializeAllLinks();

    $("#paperVersions").on('page-change.bs.table', function (e, n, s) {
        // TODO: Fix initialization?
    });
});