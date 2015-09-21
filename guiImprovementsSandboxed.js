// Generated by CoffeeScript 1.9.3

/* UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements Sandboxed Portion
// @description  Runs potentially unsafe code in a protective sandbox.
// @namespace    ahto
// @version      1.1.2
// @include      http://*flightrising.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=61626
// @grant        GM_addStyle
// @grant        GM_setValue
// @grant        GM_getValue
// ==/UserScript==
 */
var LOADING_WAIT, addCheckboxListeners, brew, brew_id, brew_n, logBrewValues, ref, setTimeout_, updateCheckbox;

LOADING_WAIT = 1000;

setTimeout_ = function(wait, f) {
  return setTimeout(f, wait);
};

if (new RegExp('http://www1\.flightrising\.com/msgs$', 'i').test(document.location.href)) {
  GM_addStyle('#ajaxbody tr.highlight-tr.selected-tr {\n    background-color: #CAA;\n}\n\n#ajaxbody tr.selected-tr {\n    background-color: #CBB;\n}');
  updateCheckbox = function(targetCheckbox) {
    var tr;
    tr = targetCheckbox.parents('tr');
    if (targetCheckbox.prop('checked')) {
      return tr.addClass('selected-tr');
    } else {
      return tr.removeClass('selected-tr');
    }
  };
  addCheckboxListeners = function() {
    return findMatches('#ajaxbody tr input[type=checkbox]').click(function(event) {
      return updateCheckbox($(event.target));
    });
  };
  addCheckboxListeners();
  findMatches('input#set', 1, 1).click(function(event) {
    var i, j, len, ref, results;
    ref = findMatches('#ajaxbody tr input[type=checkbox]');
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      i = ref[j];
      results.push(updateCheckbox($(i)));
    }
    return results;
  });
  findMatches('img#prev, img#next, button#delete-confirm-yes', 0, 3).click(function(event) {
    return setTimeout((function() {
      return addCheckboxListeners();
    }), 500);
  });
}

if (urlMatches(new RegExp('http://www1\.flightrising\.com/trading/baldwin.*', 'i'))) {
  logBrewValues = function(s) {
    if (s != null) {
      console.log(s);
    }
    console.log('brew_id:', GM_getValue('brew_id'));
    console.log('brew_n:', GM_getValue('brew_n'));
    return console.log('----------');
  };
  brew = function(id, n) {
    if (n == null) {
      n = 1;
    }
    if (n <= 0) {
      GM_setValue('brew_id');
      GM_setValue('brew_n');
      logBrewValues('reset after n=0');
      return;
    }
    $('#baldwin-transmute-btn').click();
    return setTimeout_(LOADING_WAIT, function() {
      var itemInList;
      itemInList = $("a[rel='#tooltip-" + id + "']");
      itemInList = $(itemInList[itemInList.length - 1]);
      itemInList.click();
      return setTimeout_(LOADING_WAIT, function() {
        $('#attch').click();
        return setTimeout_(LOADING_WAIT, function() {
          GM_setValue('brew_n', n - 1);
          logBrewValues('next iteration');
          return $('#transmute-confirm-ok').click();
        });
      });
    });
  };
  ref = [GM_getValue('brew_id'), GM_getValue('brew_n')], brew_id = ref[0], brew_n = ref[1];
  logBrewValues('got values');
  if ((brew_id != null) && (brew_n != null) && brew_n > 0) {
    brew(brew_id, brew_n);
  } else {
    $('#baldwin-transmute-btn').click(function() {
      return setTimeout_(LOADING_WAIT, function() {
        var dropdown, i, j, results;
        dropdown = $('#quantity');
        results = [];
        for (i = j = 2; j <= 99; i = ++j) {
          results.push(dropdown.append("<option value='1'>" + i + "</option>"));
        }
        return results;
      });
    });
    $('#attch').click(function() {
      var selectedValue;
      selectedValue = $("#" + dropdown + " option[value=" + (dropdown.val()) + "]");
      selectedValue = parseInt(selectedValue);
      if (selectedValue > 1) {

      }
    });
  }
}
