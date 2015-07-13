# vim: foldmethod=marker
### UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements
// @description  Improves the interface for Flight Rising.
// @namespace    ahto
// @version      1.11.0
// @include      http://*flightrising.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=61626
// @grant        none
// ==/UserScript==
###

### Features and changes {{{1
General:
- Adds two new links to Baldwin's Bubbling Brew.
- Removes redundant links to messages and gems.
- Flashes the title of Baldwin's Bubbling Brew when your brew is ready.
- Automatically clicks 'play again' at the HiLo game.

Auction House:
- Clicking the icons next to price ranges will let you sort by only treasure or only gems.
- Tells you how much items cost per unit.
- Adds a clear item name button.
- Clicking an item's name sets that to the name filter.
- Prices have commas in them.
###

# Consts {{{1
TREASURE = 0
GEMS     = 1

# Settings {{{1
# AH is short for Auction House
AH_BUTTON_SPACING   = '140px'
AH_UPDATE_DELAY     = 2000

# Set this to undefined for no default.
# Can be TREASURE or GEMS
AH_DEFAULT_CURRENCY = TREASURE

# Min and max times to wait before clicking play again.
HILO_CLICK_MIN =  200
HILO_CLICK_MAX = 1000

# Add/remove links to the sidebar {{{1
# pm = messages link
# ge = buy gems link
# also alternatives since the HTML changes between www1.flightrising.com and flightrising.com
findMatches('''
    a.navbar[href='main.php?p=pm'],
    a.navbar[href*='msgs'],
    a.navbar[href='main.php?p=ge'],
    a.navbar[href*='buy-gems']
''', 2, 2).remove()

# :matches() is experimental right now and it has a different name in each browser
# firefox is :-moz-any() and Chrome is :-webkit-any()
# but it would be a handy way to simplify the above

# Find the link to the crossroads and add some useful alchemy links after it.
findMatches("a.navbar[href*=crossroads]").after('''
    <a class='navbar navbar-glow-hover' href='http://www1.flightrising.com/trading/baldwin/transmute'>
        Alchemy (Transmute)
    </a>
    <a class='navbar navbar-glow-hover' href='http://www1.flightrising.com/trading/baldwin/create'>
        Alchemy (Create)
    </a>
''')

# Baldwin's Bubbling Brew {{{1
if (new RegExp('http://www1\.flightrising\.com/trading/baldwin.*', 'i')).test(window.location.href)
    BLINK_TIMEOUT = 250

    # If there are any collect buttons.
    if findMatches("input[value='Collect!']", 0, 1).length
        blinker = setInterval((->
            if document.title == 'Ready!'
                document.title = '!!!!!!!!!!!!!!!!'
            else
                document.title = 'Ready!'
        ), BLINK_TIMEOUT)

        window.onfocus = ->
            clearInterval blinker
            document.title = 'Done.'
# HiLo Game {{{1
else if (new RegExp("http://flightrising\.com/main\.php.*p=hilo", 'i')).test(window.location.href)
    setTimeout((->
            playAgain = findMatches('.mb_button[value="Play Again"]', 0, 1)
            if playAgain.length then playAgain.click()
    ), randInt(HILO_CLICK_MIN, HILO_CLICK_MAX))
# Auction House {{{1
else if (new RegExp('http://flightrising\.com/main\.php.*p=ah.*', 'i')).test(window.location.href)
    # Add a clear button for item name and put it right above the textbox.
    itemNameText = $('#searching > div:nth-child(1)')
    itemNameText.html(
        itemNameText.html() +
        '''
            <a href='javascript:$("input[name=name").val("")'>
                &nbsp;(clear)
            </a>
        '''
    )

    class AuctionListing # {{{2
        constructor: (@element) ->
            # WARNING: This might break in the future since it overrelies on :nth-child
            @numberOfItems = safeParseInt(
                @element.find('div:nth-child(1) > span:nth-child(1) > span').text()
            )

            @button = @element.find('[id*=buy_button]')

            @price = safeParseInt @button.text()
            @priceEA = @price / @numberOfItems

            @nameElement = @element.find('div:nth-child(1) > span:nth-child(2) > span:nth-child(1)')
            @name        = @nameElement.text()

        modifyElement: ->
            # Modifies @element to include some extra information.
            # This is the straightforwad method but jQuery removes everything but the
            # text if we do it like this:
            # @button.text(foo)

            if @numberOfItems > 1
                target = @button[0].childNodes[2]

                # If our target is gone that probably means the offer expired.
                if not target? then return

                if not safeParseInt(target.textContent) == @price
                    throw new Error("Tried to modify an auction house item but the price didn't match expectations.")

                priceString   = numberWithCommas(@price)
                priceEAString = numberWithCommas(Math.round @priceEA)
                target.textContent = " #{priceString} (#{priceEAString} ea)"

            # Give the new text some breathing room.
            @button.css('width', AH_BUTTON_SPACING)

            @nameElement.html(
                "<a href='javascript:$(\"input[name=name]\").val(\"#{@name}\")'>#{@name}</a>"
            )

            # TODO Why won't this work?
            #@nameElement.css('color', '#731d08')

    # Simple test for a better way to find out if the AH data gets refreshed. {{{2
    # TODO: Only works once.
    ###
    if window.browseAll?
        oldBrowseAll     = window.browseAll
        window.browseAll = (args...) ->
            console.log "window.browseAll() called"
            return oldBrowseAll args...

        $(document.head).append("""
            <script type="text/javascript">
                window.browseAll = #{window.browseAll.toString()}
            </script>
        """)

        console.log "window.browseAll() overwritten."
    else
        console.log "Couldn't find window.browseAll()"
    ###

    # Modify AH listings {{{2
    #TODO: The auction house listings aren't loaded when this gets called
    #      so I need to find an event or something. Using intervals right
    #      now is an ugly utilitarian standin for a proper solution.
    listings = undefined
    safeInterval((->
        new_listings = $('#ah_left div[id*=sale]')

        isUpdated = (->
            if not listings? then return true

            if new_listings.length == 0 or listings.length == 0
                return false

            for i in [0...listings.length]
                # need to get element[0] to un-jQuery it.
                if listings[i].element[0] != new_listings[i]
                    return true

            return false
        )()

        if isUpdated
            listings = (new AuctionListing $(i) for i in $('#ah_left div[id*=sale]'))
            i.modifyElement() for i in listings
    ), AH_UPDATE_DELAY)

    # Filter by only gems or only treasure {{{2
    treasure =
        img:   findMatches('#searching img[src="/images/layout/icon_treasure.png"]', 1, 1)
        low:   findMatches('input[name=tl]', 1, 1)
        high:  findMatches('input[name=th]', 1, 1)

    gems =
        img:   findMatches('#searching img[src="/images/layout/icon_gems.png"]', 1, 1)
        low:   findMatches('input[name=gl]', 1, 1)
        high:  findMatches('input[name=gh]', 1, 1)

    showOnly = (currency) -> # {{{3
        if currency == TREASURE
            [us, them] = [treasure, gems]
        else if currency == GEMS
            [us, them] = [gems, treasure]
        else
            throw new Error "showOnly called with invalid currency: #{currency}"

        if us.low.val() != '' or us.high.val() != ''
            us.low.val('')
            us.high.val('')
        else
            us.low.val('0')
            us.high.val('99999999999999999999')

        if them.low.val() != '' or them.high.val() != ''
            them.low.val('')
            them.high.val('')

    listener = (event) -> # {{{3
        if event.currentTarget == treasure.img[0]
            showOnly(TREASURE)
        else if event.currentTarget == gems.img[0]
            showOnly(GEMS)
        else
            throw new Error 'Something in the auction house code has gone horribly wrong.'

    # 3}}}
    if AH_DEFAULT_CURRENCY?
        showOnly AH_DEFAULT_CURRENCY
        findMatches('input[type=submit]', 1, 1).click()

    treasure.img.click listener
    gems.img.click     listener

    # Make the currency buttons look clickable by changing the cursor when you
    # hover over them.
    treasure.img.css 'cursor', 'pointer'
    gems.img.css     'cursor', 'pointer'
