// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".

//"JavaScript Next"-style

import "phoenix"
import "phoenix_html"

import $ from "jquery"

import "bootstrap"

// import "select2"

import moment from "moment"

import moment_timezone from "moment-timezone"

import "admin-lte/plugins/datepicker/bootstrap-datepicker.js"

import daterangepicker from "bootstrap-daterangepicker"

import "admin-lte/plugins/input-mask/jquery.inputmask.js"

import "admin-lte/plugins/select2/select2.full.min.js"

import "admin-lte"

// global app config stuff (move to separate files/envs at some point?)
var mpnetwork = {
  config: {
    dateformat: 'yyyy-mm-dd',
    datetimeformat: 'YYYY-MM-DD h:mm A'
  }
}

function ConvertFromUTCToLocal(dt){
  switch(dt) {
    case "":
      return "";
      break;
    default:
      return moment(dt).tz(moment.tz.guess()).format(mpnetwork.config.datetimeformat);
      break;
  }
}

function ConvertFromLocalToUTC(dt){
  switch(dt) {
    case "":
      return "";
      break;
    default:
      return moment.tz(dt, moment.tz.guess()).toISOString();
      break;
  }
}

$(function() {
  // trigger multiselect with search autocomplete
  $(".fancy").select2({
    placeholder: "Select an option",
    allowClear: true,
  });
  // trigger datepicker inputs
  $.fn.datepicker.defaults.format = mpnetwork.config.dateformat;
  $.fn.datepicker.defaults.assumeNearbyYear = true;
  $.fn.datepicker.defaults.todayHighlight = true;
  $('div.date input.form-control').datepicker();
  // convert UTC datetime values to local TZ after page load for pages with these elements
  $('div.datetime input.form-control').each(function(_i, dt){
    $(dt).val(ConvertFromUTCToLocal(dt.value));
  });
  // set up post hook to convert local TZ datetimes back to UTC just before form post
  $('form.contains-datetimes').submit(function(){
    var datetimes = $(this).find('div.datetime input.form-control');
    datetimes.each(function(_i, dt){
      $(dt).val(ConvertFromLocalToUTC(dt.value));
    });
    return true;
  });
  // trigger daterangepicker inputs
  $('div.datetime input.form-control').daterangepicker({
    singleDatePicker: true,
    autoApply: true,
    autoUpdateInput: false, // see note below
    timePicker: true,
    timePicker24Hour: false,
    timePickerIncrement: 15,
    locale: {
      format: mpnetwork.config.datetimeformat
    }
  });
  // Silly workaround to preserve initially-blank values, per http://www.daterangepicker.com/#config
  // and its "Input Initially Empty" "hack"
  // This also requires "autoUpdateInput" config to be false, above.
  $('div.datetime input.form-control').on('apply.daterangepicker', function(ev, picker) {
    $(this).val(picker.startDate.format(mpnetwork.config.datetimeformat));
  });
  // trigger phone input masks
  $(":input").inputmask();
});

// "CommonJS"-style, see http://jsmodules.io/cjs.html for comparison
// global.$ = global.jQuery = require("jquery")
// global.bootstrap = require("bootstrap")
// global.AdminLTE = require("admin-lte")



// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
