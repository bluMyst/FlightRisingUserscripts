# vim: foldmethod=marker
### UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements Sandboxed Portion
// @description  Runs potentially unsafe code in a protective sandbox.
// @namespace    ahto
// @version      1.0.0
// @include      http://*flightrising.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=61626
// @grant        GM_addStyle
// ==/UserScript==
###

injectScript = (f) -> # {{{1
    # Injects a script to run in the window's namespace.
    if typeof f == 'function'
        # Surround the function in parentheses and call it with no arguments.
        # Otherwise it'll just sit there, like this:
        # (foo) -> foo(13)
        # Instead of this:
        # ( (foo) -> foo(13) )()
        source = "(#{f})();"

    script = $("""
        <script type='application/javascript'>
            #{source}
        </script>
    """)

    # append script and immediately remove it to clean up
    $(document).append script
    script.remove()

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

    findMatches('#ajaxbody tr input[type=checkbox]').click (event) ->
        target = $(event.target)
        tr = target.parents('tr')

        if target.prop('checked')
            tr.addClass('selected-tr')
        else
            tr.removeClass('selected-tr')
