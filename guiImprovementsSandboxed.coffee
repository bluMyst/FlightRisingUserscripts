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
// @grant        GM_setValue
// @grant        GM_getValue
// ==/UserScript==
###

# Settings {{{1
LOADING_WAIT = 1000

# Functions {{{1
setTimeout_ = (wait, f) ->
    return setTimeout(f, wait)

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

# Baldwin's Bubbling Brew {{{1
if urlMatches new RegExp('http://www1\.flightrising\.com/trading/baldwin.*', 'i')
    logBrewValues = (s) ->
        if s? then console.log s
        console.log 'brew_id:', GM_getValue('brew_id')
        console.log 'brew_n:',  GM_getValue('brew_n')
        console.log '----------'

    brew = (id, n=1) ->
        if n <= 0
            GM_setValue 'brew_id'
            GM_setValue 'brew_n'
            logBrewValues 'reset after n=0'
            return

        $('#baldwin-transmute-btn').click() # (Transmute)

        setTimeout_ LOADING_WAIT, ->
            itemInList = $ "a[rel='#tooltip-#{id}']"

            # Always start with the last one in the list.
            itemInList = $ itemInList[itemInList.length-1]
            itemInList.click()

            setTimeout_ LOADING_WAIT, ->
                $('#attch').click() # (Add) / Cancel

                setTimeout_ LOADING_WAIT, ->
                    GM_setValue 'brew_n', n-1
                    logBrewValues 'next iteration'
                    $('#transmute-confirm-ok').click() # (Transmute) / Go Back

    [brew_id, brew_n] = [GM_getValue('brew_id'), GM_getValue('brew_n')]
    logBrewValues 'got values'

    if brew_id? and brew_n? and brew_n > 0
        brew(brew_id, brew_n)
    else
        $('#baldwin-transmute-btn').click ->
            setTimeout_ LOADING_WAIT, ->
                dropdown = $ '#quantity'

                for i in [2..99]
                    dropdown.append "<option value='1'>#{i}</option>"

        $('#attch').click ->
            # TODO get dropdown again
            selectedValue = $ "##{dropdown} option[value=#{dropdown.val()}]"
            selectedValue = parseInt selectedValue

            if selectedValue > 1
                return 
