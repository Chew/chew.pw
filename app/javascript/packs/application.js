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

    // If cant has a value, click the #invertButtonToWhitelist button
    if (cant.val() !== '') {
        can.val(cant.val());
        invertButtonToBlackList(null);
    }
});

window.initializeTooltips = function() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl)
    });
}

window.initializeTooltips();

const toastElList = [].slice.call(document.querySelectorAll('.toast'));
const toastList = toastElList.map(function (toastEl) {
    let toast = new bootstrap.Toast(toastEl, {})
    toast.show();

    return toast;
});

// Every time a letter is typed while this box is focused, move on to the next element
$(".wordle-letter").keyup(function(e) {
    // Store value of input
    let value = $(this).val();

    // Every time backspace is pressed, move on to the previous element
    if (e.keyCode === 8) {
        $(this).prev().focus();
        return;
    }

    // Ensure the value is a letter a-z, remove it if it's not
    if (value.length === 1 && !/[a-z]/i.test(value)) {
        $(this).val('');
    }

    // make sure the input box only has one letter. if there's more than one, remove the extra ones
    if (value.length > 1) {
        $(this).val(value.slice(0, 1));
        $(this).next().focus();
    } else if (value.length === 1) {
        // If there's only one letter, move on to the next element
        $(this).next().focus();
    }
});

const can = $("input[name='can']");
const cant = $("input[name='cant']");

// Listen for #hideNotPossible checkbox click
$("#hideNotPossible").change(function() {
    if ($(this).is(":checked")) {
        // add display:none to all .wordle-valid
        $(".wordle-valid").addClass('d-none');
    } else {
        // remove display:none from all .wordle-valid
        $(".wordle-valid").removeClass('d-none');
    }
});

// Connections Answer
$("#connectionsAnswer").click((e) => {
    e.preventDefault();

    // get today's date as YYYY-MM-DD (as local time)
    const localToday = new Date();
    const today = new Date(localToday.getTime() - (localToday.getTimezoneOffset() * 60000));

    // Append ?date=YYYY-MM-DD to the URL
    let url = new URL(window.location.href);
    url.searchParams.set("date", today.toISOString().slice(0, 10));

    // Redirect to the new URL
    window.location = url.href;
})

// Listen for the #invertButtonToBlacklist button click
const invertButtonToBlackList = function(e) {
    if (e) e.preventDefault();
    // Move the value of can to cant, then remove the value of cant
    let canVal = can.val();
    cant.val(canVal);
    can.val('');
    $("#letter-whitelist").addClass('d-none');
    $("#letter-blacklist").removeClass('d-none');
};

$("#invertButtonToBlacklist").click(invertButtonToBlackList);

const invertButtonToWhitelist = function(e) {
    if (e) e.preventDefault();
    // Move the value of cant to can, then remove the value of can
    let cantVal = cant.val();
    can.val(cantVal);
    cant.val('');
    $("#letter-blacklist").addClass('d-none');
    $("#letter-whitelist").removeClass('d-none');
};

$("#invertButtonToWhitelist").click(invertButtonToWhitelist);

$("#clear-fields").click(function(e) {
    e.preventDefault();
    // clear all non-hidden, non-submit input values inside the form tag
    $("input:not(:submit):not(:hidden)").val('');
});

$("#season-dropdown").change(() => {
    $("#season-form").submit();
});

Rails.start()
// Turbolinks.start()
//ActiveStorage.start()
