// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
//import Turbolinks from "turbolinks"
//import * as ActiveStorage from "@rails/activestorage"
import "channels"

import * as bootstrap from 'bootstrap';
import jQuery from 'jquery'
require("jquery-ui")

window.$ = jQuery;
window.jQuery = jQuery;

window.loadingSpinner = `<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>`;

require('bootstrap-table')

$(document).ready(function() {
    $('button[data-toggle]').mouseenter(function () {
        $(this).attr('data-bs-toggle', $(this).attr('data-toggle')); //does the switch
        $(this).removeAttr('data-toggle'); //clears out the old one if you need to
    });
});

window.initializeTooltips = function() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl)
    });
}


Rails.start()
// Turbolinks.start()
//ActiveStorage.start()
