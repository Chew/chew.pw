// Select all links
//var allLinks = document.querySelectorAll('a[href]');
window.onload = function() {
    const allLinks = document.links;

// Bind the event handler to each link individually
    let i = 0, n = allLinks.length;
    for (; i < n; i++) {
        //allLinks[i].addEventListener('click', function (event) {});
        const href = allLinks[i].getAttribute('href') || '';
        if (!href.includes("build")) {
            continue;
        }
        allLinks[i].onclick = function (e) {
            e.target.outerHTML = `<span id="${e.target.id}">Loading...</span>`
        };
    }
}