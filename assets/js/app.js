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

import $ from 'jquery'

import "phoenix"
import "phoenix_html"

import "bootstrap"

import moment from "moment"

window.moment = moment; // for testing moment functions in console

import moment_timezone from "moment-timezone"

import "bootstrap-datepicker"

import daterangepicker from "bootstrap-daterangepicker"

import "bootstrap-carousel-swipe"

import "admin-lte/plugins/input-mask/jquery.inputmask"

import "admin-lte"

import Quill from "quill"

import "bootstrap-table"

import "dropzone"

require("select2")($); // had to do it this way otherwise it was not binding to jQuery objects

// global app config stuff (move to separate files/envs at some point?)
var mpnetwork = {
  config: {
    tz: moment.tz.guess(), //'America/New_York'
    datepicker_dateformat: 'm/d/yyyy',
    moment_local_dateformat: 'M/D/YYYY',
    local_datetimeformat: 'M/D/YYYY h:mm A',
    utc_dateformat: 'YYYY-MM-DD',
    friendly_datetimeformat: 'ddd MMM D YYYY @ h:mmA'
  }
}

function ConvertFromUTCToLocalDatetime(utc_dt, tz = mpnetwork.config.tz) {
  switch (utc_dt) {
    case "":
      return "";
    default:
      var local_dt = moment.utc(utc_dt).tz(tz).format(mpnetwork.config.local_datetimeformat);
      // alert("converting from utc " + utc_dt + " to local " + local_dt);
      return local_dt;
  }
}
// "export" this so it can be accessed from bootstrap-table config and console
window.ConvertFromUTCToLocalDatetime = ConvertFromUTCToLocalDatetime;

function ConvertFromUTCToLocalDate(utc_d) {
  switch (utc_d) {
    case "":
      return "";
    default:
      var local_d = moment.utc(utc_d).format(mpnetwork.config.moment_local_dateformat);
      // alert("converting from utc " + utc_d + " to local " + local_d);
      return local_d;
  }
}
// "export" this so it can be accessed from bootstrap-table config and console
window.ConvertFromUTCToLocalDate = ConvertFromUTCToLocalDate;

function ConvertFromFriendlyToUTCDatetime(local_dt, tz = mpnetwork.config.tz) {
  switch (local_dt) {
    case "":
      return "";
    default:
      var only_first = local_dt.split(/; ?/)[0]
      var parsed_dt = moment.tz(only_first, mpnetwork.config.friendly_datetimeformat, tz)
      // var utc_dt = parsed_dt.add(-parsed_dt.utcOffset(), 'm').local().format();
      var utc_dt = parsed_dt.utc().format();
      return utc_dt;
  }
}
// "export" this so it can be accessed from bootstrap-table config and console
window.ConvertFromFriendlyToUTCDatetime = ConvertFromFriendlyToUTCDatetime;

function ConvertFromLocalToUTCDatetime(local_dt, tz = mpnetwork.config.tz) {
  switch (local_dt) {
    case "":
      return "";
    default:
      var parsed_dt = moment.tz(local_dt, mpnetwork.config.local_datetimeformat, tz)
      // var utc_dt = parsed_dt.add(-parsed_dt.utcOffset(), 'm').local().format();
      var utc_dt = parsed_dt.utc().format();
      // var utc_dt = moment.utc(moment.local(local_dt)).toISOString();
      // alert("converting local " + local_dt + " to UTC " + utc_dt);
      return utc_dt;
      // return local_dt;
  }
}
// "export" this so it can be accessed from bootstrap-table config and console
window.ConvertFromLocalToUTCDatetime = ConvertFromLocalToUTCDatetime;

function ConvertFromLocalToUTCDate(local_d) {
  switch (local_d) {
    case "":
      return "";
    default:
      return moment(local_d, mpnetwork.config.moment_local_dateformat).format(mpnetwork.config.utc_dateformat);
  }
}
// "export" this so it can be accessed from bootstrap-table config and console
window.ConvertFromLocalToUTCDate = ConvertFromLocalToUTCDate;

function IsNonblankString(maybe_str) {
  return ((typeof maybe_str === 'string' || maybe_str instanceof String) && (maybe_str.trim() !== ""));
}
// "export" this so it can be accessed from bootstrap-table config and console
window.IsNonblankString = IsNonblankString;

function USDatetimeSorter(a, b) {
  if (!IsNonblankString(a)) return -1;
  if (!IsNonblankString(b)) return 1;
  a = ConvertFromLocalToUTCDatetime(a);
  b = ConvertFromLocalToUTCDatetime(b);
  if (a > b) return 1;
  if (a < b) return -1;
  return 0;
}
// "export" this so it can be accessed from bootstrap-table config and console
window.USDatetimeSorter = USDatetimeSorter;

function PriceSorter(a, b) {
  if (!IsNonblankString(a)) return -1;
  if (!IsNonblankString(b)) return 1;
  a = parseInt(a.replace(/[\$\,\.]/g, ""));
  b = parseInt(b.replace(/[\$\,\.]/g, ""));
  if (a > b) return 1;
  if (a < b) return -1;
  return 0;
}
// "export" this so it can be accessed from bootstrap-table config and console
window.PriceSorter = PriceSorter;

function StripTags(str) {
  return str.replace(/(<([^>]+)>)/ig, "").replace(/\s+/g, " ").trim();
}
// "export" this so it can be accessed from bootstrap-table config and console
window.StripTags = StripTags;

function OpenHouseSorter(a, b) {
  if (!IsNonblankString(a)) return -1;
  if (!IsNonblankString(b)) return 1;
  a = ConvertFromFriendlyToUTCDatetime(StripTags(a));
  b = ConvertFromFriendlyToUTCDatetime(StripTags(b));
  if (a > b) return 1;
  if (a < b) return -1;
  return 0;
}
// "export" this so it can be accessed from bootstrap-table config and console
window.OpenHouseSorter = OpenHouseSorter;

function AddressWithLinksSorter(a, b) {
  if (!IsNonblankString(a)) return -1;
  if (!IsNonblankString(b)) return 1;
  a = StripTags(a);
  b = StripTags(b);
  if (a > b) return 1;
  if (a < b) return -1;
  return 0;
}
// "export" this so it can be accessed from bootstrap-table config and console
window.AddressWithLinksSorter = AddressWithLinksSorter;
// ondocumentload functionality
$.when($.ready).then(function() {
  // trim spaces before form submission (such as logins)
  $(".strip-before-submission").each(function(_i, formfield) {
    var form = $(formfield.form);
    form.submit(function(f) {
      formfield.value = formfield.value.trim();
    })
  });

  // trigger multiselect with search autocomplete
  $(".fancy").select2({
    placeholder: "Select an option",
    allowClear: true,
  });

  // convert UTC datetime values to local TZ after page load for pages with these elements
  $('div.datetime input.form-control').each(function(_i, dt) {
    $(dt).val(ConvertFromUTCToLocalDatetime(dt.value));
  });

  // convert UTC date values to localized dates after page load for pages with these elements
  $('div.date input.form-control').each(function(_i, d) {
    $(d).val(ConvertFromUTCToLocalDate(d.value));
  });

  // set up post hook to convert local TZ datetimes back to UTC just before form post
  $('form.contains-datetimes').submit(function() {
    var datetimes = $(this).find('div.datetime input.form-control');
    datetimes.each(function(_i, dt) {
      $(dt).val(ConvertFromLocalToUTCDatetime(dt.value));
    });
    var dates = $(this).find('div.date input.form-control');
    dates.each(function(_i, d) {
      $(d).val(ConvertFromLocalToUTCDate(d.value));
    });
    return true;
  });

  // config and trigger datepicker inputs
  $.fn.datepicker.defaults.format = mpnetwork.config.datepicker_dateformat;
  $.fn.datepicker.defaults.assumeNearbyYear = true;
  $.fn.datepicker.defaults.todayHighlight = true;
  $('div.date input.form-control').not('[readonly]').datepicker();

  // config and trigger daterangepicker inputs
  $('div.datetime input.form-control').not('[readonly]').daterangepicker({
    singleDatePicker: true,
    autoApply: true,
    autoUpdateInput: false, // see note below
    timePicker: true,
    timePicker24Hour: false,
    timePickerIncrement: 15,
    locale: {
      format: mpnetwork.config.local_datetimeformat
    }
  });

  // Silly workaround to preserve initially-blank values, per http://www.daterangepicker.com/#config
  // and its "Input Initially Empty" "hack"
  // This also requires "autoUpdateInput" config to be false, above.
  $('div.datetime input.form-control').on('apply.daterangepicker', function(ev, picker) {
    $(this).val(picker.startDate.format(mpnetwork.config.local_datetimeformat));
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

  // rich text editor config
  // var FontAttributor = Quill.import('attributors/style/font');
  // Quill.register(FontAttributor, true);
  // FontAttributor.whitelist = [
  //   'helvetica', 'sofia', 'slabo', 'roboto', 'inconsolata', 'ubuntu'
  // ];
  if ($('#rte_container').length) {
    var SizeStyle = Quill.import('attributors/style/size');
    SizeStyle.whitelist = ['10px', '18px', '24px'];
    Quill.register(SizeStyle, true);
    var editor = new Quill('#rte_container', {
      modules: {
        toolbar: [
          ['bold', 'italic', 'underline'],
          [{ 'font': [] }, { 'color': [] }, 'link'],
          // Took out indenting since it was class-based and thus incompatible with html email
          // (customizing to style-based is a pain, see below)
          // and nobody would probably use it. Left in as an example for posterity.
          // [{ 'indent': '-1'}, { 'indent': '+1' }],
          // For the size menu, note that (extensive and specific) menu item styling still has to be done on every item here;
          // in css, search for "RICH TEXT EDITOR STYLES"
          [{ 'size': ['10px', false, '18px', '24px'] }],
          ['image'],
          ['clean']
        ]
      },
      placeholder: 'Email signature...',
      theme: 'snow' // or 'bubble'
    });
  };
  // for config inspection:
  // console.log(Quill.imports);
  // set up post hook to copy contenteditable div content to hidden form element before form post
  $('form.contains-richtexteditor').submit(function() {
    $('.rte-target').val($('#rte_container div.ql-editor').html());
    return true;
  })
  // copy html form val data to contenteditable container on page load if exists
  $('#rte_container div.ql-editor').html($('.rte-target').val());
  // $('form.dropzone').dropzone({});
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
