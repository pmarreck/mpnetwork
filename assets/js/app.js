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

import "bootstrap-datepicker"

import daterangepicker from "bootstrap-daterangepicker"

import "bootstrap-carousel-swipe"

import "admin-lte/plugins/input-mask/jquery.inputmask"

import "select2"

import "admin-lte"

// global app config stuff (move to separate files/envs at some point?)
var mpnetwork = {
  config: {
    datepicker_dateformat: 'm/d/yyyy',
    moment_dateformat: 'M/D/YYYY',
    datetimeformat: 'M/D/YYYY h:mm A'
  }
}

function ConvertFromUTCToLocalDatetime(utc_dt){
  switch(utc_dt) {
    case "":
      return "";
      break;
    default:
      var local_dt = moment.utc(utc_dt).tz(moment.tz.guess()).format(mpnetwork.config.datetimeformat);
      // alert("converting from utc " + utc_dt + " to local " + local_dt);
      return local_dt;
      break;
  }
}

function ConvertFromUTCToLocalDate(utc_d){
  switch(utc_d) {
    case "":
      return "";
      break;
    default:
      var local_d = moment.utc(utc_d).format(mpnetwork.config.moment_dateformat);
      // alert("converting from utc " + utc_d + " to local " + local_d);
      return local_d;
      break;
  }
}

function ConvertFromLocalToUTCDatetime(local_dt){
  switch(local_dt) {
    case "":
      return "";
      break;
    default:
      var utc_dt = moment(local_dt).add(-moment(local_dt).utcOffset(), 'm').local().format();
      // var utc_dt = moment.utc(moment.local(local_dt)).toISOString();
      // alert("converting local " + local_dt + " to UTC " + utc_dt);
      return utc_dt;
      // return local_dt;
      break;
  }
}

function ConvertFromLocalToUTCDate(local_d){
  switch(local_d) {
    case "":
      return "";
      break;
    default:
      // alert("about to try to convert this date from local to utc:" + local_d);
      var utc_d = moment(local_d).toISOString(); //moment(local_d).local().format();
      // var utc_d = moment.utc(moment.local(local_d)).toISOString();
      // alert("converting local " + local_d + " to UTC " + utc_d);
      return utc_d;
      // return local_d;
      break;
  }
}

$(function() {
  // trigger multiselect with search autocomplete
  $(".fancy").select2({
    placeholder: "Select an option",
    allowClear: true,
  });
  // convert UTC datetime values to local TZ after page load for pages with these elements
  $('div.datetime input.form-control').each(function(_i, dt){
    $(dt).val(ConvertFromUTCToLocalDatetime(dt.value));
  });
  // convert UTC date values to localized dates after page load for pages with these elements
  $('div.date input.form-control').each(function(_i, d){
    $(d).val(ConvertFromUTCToLocalDate(d.value));
  });
  // set up post hook to convert local TZ datetimes back to UTC just before form post
  $('form.contains-datetimes').submit(function(){
    var datetimes = $(this).find('div.datetime input.form-control');
    datetimes.each(function(_i, dt){
      $(dt).val(ConvertFromLocalToUTCDatetime(dt.value));
    });
    var dates = $(this).find('div.date input.form-control');
    dates.each(function(_i, d){
      $(d).val(ConvertFromLocalToUTCDate(d.value));
    });
    return true;
  });
  // config and trigger datepicker inputs
  $.fn.datepicker.defaults.format = mpnetwork.config.datepicker_dateformat;
  $.fn.datepicker.defaults.assumeNearbyYear = true;
  $.fn.datepicker.defaults.todayHighlight = true;
  $('div.date input.form-control').datepicker();
  // config and trigger daterangepicker inputs
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

  // add link toggle behavior in search examples
  $('a#toggle_examples').click(function(e) {
    e.preventDefault();
    $('#examples').toggle();
  })

  // carousel swipe config
  $("#photo-carousel").carousel({
    swipe: 30 // percent-per-second, default is 50. Pass false to disable swipe
  });
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
