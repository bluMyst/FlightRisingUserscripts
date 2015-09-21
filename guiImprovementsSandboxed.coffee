# vim: foldmethod=marker
### UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements Sandboxed Portion
// @description  Runs potentially unsafe code in a protective sandbox.
// @namespace    ahto
// @version      1.1.2
// @include      http://*flightrising.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=75750
// @grant        GM_addStyle
// ==/UserScript==
###

# Messages window (highlight selected) {{{1
if new RegExp('http://www1\.flightrising\.com/msgs$', 'i').test document.location.href
    GM_addStyle('''
        #ajaxbody tr.highlight-tr.selected-tr {
            background-color: #CAA;
        }

        #ajaxbody tr.selected-tr {
            background-color: #CBB;
        }
    ''')

    updateCheckbox = (targetCheckbox) ->
        tr = targetCheckbox.parents 'tr'

        if targetCheckbox.prop 'checked'
            tr.addClass 'selected-tr'
        else
            tr.removeClass 'selected-tr'

    addCheckboxListeners = ->
        findMatches('#ajaxbody tr input[type=checkbox]').click (event) ->
            updateCheckbox $ event.target

    addCheckboxListeners()

    findMatches('input#set', 1, 1).click (event) ->
        for i in findMatches '#ajaxbody tr input[type=checkbox]'
            updateCheckbox $ i

    findMatches('img#prev, img#next, button#delete-confirm-yes', 0, 3).click (event) ->
        setTimeout((-> addCheckboxListeners()), 500)
