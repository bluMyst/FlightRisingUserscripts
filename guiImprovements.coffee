# vim: foldmethod=marker
### UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements
// @description  Improves the interface for Flight Rising.
// @namespace    ahto
// @version      1.6
// @include      http://*flightrising.com/*
// @grant        none
// ==/UserScript==
###

### Features and changes {{{1
- Removes redundant links to messages and gems.
- Adds two new links to Baldwin's Bubbling Brew.
- Flashes the title of Baldwin's Bubbling Brew when your brew is ready.
- At the Auction House, clicking the icons next to price ranges will let you sort by only treasure or only gems.
- Tells you how much items cost each at the auction house.
###

findMatches = (selector, min=1, max=Infinity) -> # {{{1
    matches = $(selector)

    if min <= matches.length <= max
        return matches
    else
        throw Error("#{matches.length} matches (expected #{min}-#{max}) found for selector: #{selector}")

safeParseInt = (s) -> # {{{1
    n = parseInt(s)

    # Because apparently NaN != NaN...
    if isNaN(s)
        throw new Error("Unable to parse int from \"#{s}\"")
    else
        return n

safeInterval = (func, wait, times) -> # {{{1
    # Source: http://www.thecodeship.com/web-development/alternative-to-javascript-evil-setinterval/
    # Changed a bit from there.
    interv = ((w, t) ->
        return (->
            if not t? or t-- > 0
                setTimeout(interv, w)
                try
                    # This is sorta the same thing as func()
                    func.call(null)
                catch e
                    t = 0
                    #TODO: Why e.toString? Why not e?
                    throw e.toString()
        )
    )(wait, times)

    setTimeout(interv, wait)

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
if /http:\/\/www1.flightrising.com\/trading\/baldwin.*/i.test(window.location.href)
    BLINK_TIMEOUT = 250

    # If there are any collect buttons.
    if findMatches("input[value='Collect!']", 0, 1).length != 0
        blinker = setInterval((->
            if document.title == 'Ready!'
                document.title = '!!!!!!!!!!!!!!!!'
            else
                document.title = 'Ready!'
        ), BLINK_TIMEOUT)

        window.onfocus = ->
            clearInterval blinker
            document.title = 'Done.'
# Auction House {{{1
else if /http:\/\/flightrising\.com\/main\.php\?.*p=ah.*/.test(window.location.href)
    #TODO Add a clear button for item name.
    #TODO Make item names clickable to add them to item name field.
    TREASURE = 0
    GEMS     = 1

    class AuctionListing # {{{2
        constructor: (@element) -> # {{{3
            # WARNING: This might break in the future since it overrelies on :nth-child
            @numberOfItems = safeParseInt(
                @element.find('div:nth-child(1) > span:nth-child(1) > span').text()
            )

            @button = @element.find('[id*=buy_button]')

            # TODO: Testing @button.find as a boolean doesn't make sense to me right now.
            if @button.find('img[src="/images/layout/icon_gems.png"]')
                @currency = GEMS
            else if @button.find('img[src="/images/layout/icon_treasure.png"]')
                @currency = TREASURE
            else
                throw new Error("Unable to find currency for an auction house item.")

            @price = safeParseInt @button.text()
            @priceEA = @price / @numberOfItems

        modifyElement: -> # {{{3
            # Modifies @element to include some extra information.
            # This is the straightforwad method but jQuery removes everything but the
            # text if we do it like this:
            # @button.text(" #{@price} (#{Math.round @priceEA} ea)")

            if @numberOfItems > 1
                target = @button[0].childNodes[2]

                # If the offer expires then our target is gone.
                if not target? then return

                if not safeParseInt(target.textContent) == @price
                    throw new Error("Tried to modify an auction house item but the price didn't match expectations.")

                target.textContent = " #{@price} (#{Math.round @priceEA} ea)"

            # Give the new text some breathing room.
            @button.css('width', '150px')

    # Modify AH listings {{{2
    #TODO: The auction house listings aren't loaded when this gets called
    #      so I need to find an event or something. Using intervals right
    #      now as an ugly utilitarian standin for a proper solution.
    listings = undefined
    safeInterval((->
        # TODO Cannot read property 'length' of undefined.
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
    ), 2000)

    # Filter by only gems or only treasure {{{2
    treasure = # {{{3
        img:   findMatches('#searching img[src="/images/layout/icon_treasure.png"]', 1, 1)
        low:   findMatches('input[name=tl]', 1, 1)
        high:  findMatches('input[name=th]', 1, 1)

    gems = # {{{3
        img:   findMatches('#searching img[src="/images/layout/icon_gems.png"]', 1, 1)
        low:   findMatches('input[name=gl]', 1, 1)
        high:  findMatches('input[name=gh]', 1, 1)

    listener = (event) -> # {{{3
        if event.currentTarget == treasure.img[0]
            [us, them] = [treasure, gems]
        else if event.currentTarget == gems.img[0]
            [us, them] = [gems, treasure]
        else
            #TODO: Least helpful error message of all time.
            throw new Error('Something went wrong with the auction house code.')

        if us.low.val() != '' or us.high.val() != ''
            us.low.val('')
            us.high.val('')
        else
            us.low.val('0')
            us.high.val('99999999999999999999')

        if them.low.val() != '' or them.high.val() != ''
            them.low.val('')
            them.high.val('')

    treasure.img.click listener # {{{3
    gems.img.click     listener
