# vim: foldmethod=marker
### UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements
// @description  Improves the interface for Flight Rising.
// @namespace    ahto
// @version      1.16.0
// @include      http://*flightrising.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=61626
// @grant        none
// ==/UserScript==
###

### Features and changes {{{1
General:
- Adds two new links to Baldwin's Bubbling Brew.
- Removes redundant links to messages and gems.
- Adds commas to various numbers around the site.
- Automatically bonds with familiars.

Auction House:
- Clicking the icons next to price ranges will let you sort by only treasure or only gems.
- Tells you how much items cost per unit.
- Adds a clear item name button.
- Clicking an item's name sets that to the name filter.

Baldwin's Bubbling Brew:
- Replaces useless dialog text with a handy guide.
- Flashes title when your brew is ready. (Leave BBB running in a background tab)

Higher or Lower game:
- Automatically clicks 'play again'.
- Added keyboard shortcuts for each of the guesses.
###

# Consts {{{1
TREASURE = 0
GEMS     = 1

TD_ATTR = 'style="font-size:12px;"'
BBB_GUIDE = """
    <table>
        <tr>
            <th #{TD_ATTR}><b>Muck (Familiars)</b></th>
            <th #{TD_ATTR}><b>Slime (Apparel)</b></th>
            <th #{TD_ATTR}><b>Misc</b></th>
        </tr>
        <tr>
            <td #{TD_ATTR}>Copper 50%</td>
            <td #{TD_ATTR}>Grey 70%(?)</td>
            <td #{TD_ATTR}>Green 45%</td>
        </tr>
        <tr>
            <td #{TD_ATTR}>Silver 30%</td>
            <td #{TD_ATTR}>White 20%(?)</td>
            <td #{TD_ATTR}>Yellow 20%</td>
        </tr>
        <tr>
            <td #{TD_ATTR}>Gold 20%</td>
            <td #{TD_ATTR}>Black 10%(?)</td>
            <td #{TD_ATTR}>Orange 15%</td>
        </tr>
        <tr> <td/> <td/> <td #{TD_ATTR}>Red 10%</td> </tr>
        <tr> <td/> <td/> <td #{TD_ATTR}>Purple 8%</td> </tr>
        <tr> <td/> <td/> <td #{TD_ATTR}>Blue 2%</td> </tr>
    </table>
    <b>
        <br>
        Misc:<br>
        Ooze (Material), Sludge (Trinkets), Goo (Food)
    </b>
"""

# Settings {{{1
# AH is short for Auction House
AH_BUTTON_SPACING   = '140px'
AH_UPDATE_DELAY     = 2000

# Set this to undefined for no default.
# Can be TREASURE or GEMS
AH_DEFAULT_CURRENCY = undefined

# Min and max times to wait before clicking a button.
CLICK_TIMEOUT_MIN =  300
CLICK_TIMEOUT_MAX = 1000

BBB_BLINK_TIMEOUT = 250

# Functions {{{1
exit = ->
    throw new Error 'Not an error just exiting early'

# General improvements {{{1
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

if /www1/.test(window.location.href)
    treasureIndicator = findMatches('a.loginbar.loginlinks[title*=treasure]', 1, 1)
    currentTreasure   = numberWithCommas safeParseInt treasureIndicator.text()

    newHTML = treasureIndicator.html().replace(
        /\d+/,
        currentTreasure,
    )

    treasureIndicator.html(newHTML)
else
    treasureIndicator = findMatches('span#user_treasure', 1, 1)
    currentTreasure   = numberWithCommas safeParseInt treasureIndicator.text()
    treasureIndicator.text(currentTreasure)

# Baldwin's Bubbling Brew {{{1
if (new RegExp('http://www1\.flightrising\.com/trading/baldwin.*', 'i')).test(window.location.href)
    # If there are any collect buttons.
    if findMatches("input[value='Collect!']", 0, 1).length
        blinker = setInterval((->
            if document.title == 'Ready!'
                document.title = '!!!!!!!!!!!!!!!!'
            else
                document.title = 'Ready!'
        ), BBB_BLINK_TIMEOUT)

        window.onfocus = ->
            clearInterval blinker
            document.title = 'Done.'

    if (new RegExp('/baldwin/create')).test(window.location.href)
        bubble   = findMatches('.baldwin-create-speech-bubble', 1, 1)
        instruct = findMatches('.baldwin-create-instruct', 1, 1)

        bubble.css('padding', '5px').css('right', 'inherit')
        instruct.css('background', 'inherit')
        bubble.html BBB_GUIDE
# Marketplace {{{1
if (new RegExp('http://flightrising\.com/main\.php.*p=market', 'i')).test(window.location.href)
    for price in findMatches('#market > div > div:nth-child(3) > div:nth-child(4)', 1)
        price = $(price)
        price.text(
            numberWithCommas safeParseInt price.text()
        )
# HiLo Game {{{1
else if (new RegExp("http://flightrising\.com/main\.php.*p=hilo", 'i')).test(window.location.href)
    guesses = parseInt(
        findMatches(
            '#super-container > div:nth-child(2) > div:nth-child(4) > div:nth-child(2)',
            1, 1,
        ).text()
    )

    if guesses > 0
        playAgain = findMatches('.mb_button[value="Play Again"]', 0, 1)
        if playAgain.length
            setTimeout(
                (-> playAgain.click()),
                randInt(CLICK_TIMEOUT_MIN, CLICK_TIMEOUT_MAX),
            )
        else
            # Add keyboard shortcut instructions in place of the normal useless ones.
            # TODO Removes the thing that tells you how much money you'll win.
            findMatches('#super-container > div:nth-child(3) > div:nth-child(3)', 1, 1).html(
                'Press <b>j (lower)</b> or <b>k (higher)</b>, or use the buttons on the left.'
            )

            buttonLo = findMatches('map[name=hilo_map] > area[href*="choice=lo"]', 1, 1)
            buttonHi = findMatches('map[name=hilo_map] > area[href*="choice=hi"]', 1, 1)

            $(document).keypress((e) ->
                switch String.fromCharCode(e.charCode).toLowerCase()
                    when 'j'
                        buttonLo.click()
                    when 'k'
                        buttonHi.click()
                    else
                        console.log "Got unrechognized charCode: #{e.charCode}"
            )
# Lair (for auto-bond) {{{1
else if (new RegExp("http://flightrising\.com/main\.php.*p=lair", 'i')).test(window.location.href)
    if (bondButton = findMatches('img[src*="button_bond.png"]', 0, 1)).length
        setTimeout(
            (->
                bondButton.click()
                setTimeout(
                    (->
                        findMatches('button#no', 1, 1).click()
                    ),
                    randInt(CLICK_TIMEOUT_MIN, CLICK_TIMEOUT_MAX)
                )
            ),
            randInt(CLICK_TIMEOUT_MIN, CLICK_TIMEOUT_MAX)
        )
# Auction House {{{1
else if (new RegExp('http://flightrising\.com/main\.php.*p=ah', 'i')).test(window.location.href)
    getTab = -> #{{{2
        if (tab = /[?&]tab=([^&]+)/.exec(window.location.href))?
            tab = tab[1]
        else
            tab =  'food'

        if not tab in ['food', 'mats', 'app', 'dragons', 'fam', 'battle', 'skins', 'other']
            throw new Error "Detected tab as invalid option #{postData.tab.toString()}."

        return tab

    #2}}}
    if getTab() != 'dragons'
        # Add a clear button for item name and put it right above the textbox. {{{2
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

                target = @button[0].childNodes[2]

                # If our target is gone that probably means the offer expired.
                if not target? then return

                if not safeParseInt(target.textContent) == @price
                    throw new Error("Tried to modify an auction house item but the price didn't match expectations.")

                priceString   = numberWithCommas(@price)
                priceEAString = numberWithCommas(Math.round @priceEA)

                if @numberOfItems > 1
                    target.textContent = " #{priceString} (#{priceEAString} ea)"
                else
                    target.textContent = " #{priceString}"

                # Give the new text some breathing room.
                @button.css('width', AH_BUTTON_SPACING)

                @nameElement.html(
                    "<a href='javascript:$(\"input[name=name]\").val(\"#{@name}\")'>#{@name}</a>"
                )

                # TODO Why won't this work?
                #@nameElement.css('color', '#731d08')

        class FormData # {{{2
            constructor: (@form) ->

            field: (name, newValue) ->
                # pass no newValue to get current value.
                field = @form.find "[name=#{name}]"

                if newValue
                    return field.val(newValue)
                else
                    return field.val()

        # Modify AH listings {{{2
        listings = undefined
        updateListings = window.updateListings = ->
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

        #safeInterval(updateListings, AH_UPDATE_DELAY)

        # Overwrite browseAll() {{{2

        form = new FormData findMatches('form#searching', 1, 1)

        browseAllBackup = window.browseAll = (args...) -> # {{{3
            console.log 'browseAll called with', args
            # tl = treasure low  gh = gems high
            # Arguments are:
            # tab, page, [maybe cat], [lohi], [maybe name], ordering, direct
            # lohi = [treasure lohi] or [gem lohi] or [nothing]
            # X lohi = X hi or X lo or (X lo, X hi)

            # Build postData {{{4
            postData = {}

            [
                postData.tab,
                postData.page,
                ...,
                postData.ordering,
                postData.direct,
            ] = args

            if not postData.page?
                m = findMatches('#ah_left > div:nth-child(3) > span', 0, 1)

                if m.length
                    postData.page = m.text()
                else
                    console.log 'No page element found, assuming only 1 page.'
                    postData.page = '1'

            if not postData.tab?
                postData.tab = getTab()

            if not postData.ordering?
                if $('img[src*="button_expiration_active.png"]').length
                    postData.ordering = 'expiration'
                else if $('img[src*="button_price_active.png"]').length
                    postData.ordering = 'cost'
                else
                    throw new Error "Couldn't detect ordering (expiration or price)."

            if not postData.direct?
                if $('img[src*="button_ascending_active.png"]').length
                    postData.direct = 'ASC'
                else if $('img[src*="button_descending_active.png"]').length
                    postData.direct = 'DESC'
                else
                    throw new Error "Couldn't detect sorting direction."

            if (cat = form.field 'cat').length
                postData.cat = cat

            if (name = form.field 'name').length
                postData.name = name

            tl = form.field 'tl'
            th = form.field 'th'
            gl = form.field 'gl'
            gh = form.field 'gh'

            [tll, thl, gll, ghl] = [tl.length, th.length, gl.length, gh.length]
            filledFields = 0

            for i in [tll, thl, gll, ghl]
                if i then filledFields += 1

            # Defaults to treasure just like the original code does.
            if tll or thl
                if tll then postData.tl = tl
                if thl then postData.th = th
            else if gll or ghl
                if gll then postData.gl = gl
                if ghl then postData.gh = gh

            # 4}}}
            console.log 'Posting', postData
            $.ajax({
                type: "POST",
                data:  postData,
                url:   "includes/ah_buy_#{postData.tab}.php",
                cache: false,
            }).done((stuff) ->
                # remove the browseAll HTML
                # TODO Syntax error because stuff is a string and doesn't parse (?)
                #$(stuff).find('div:nth-child(2) > script:nth-child(2)').remove()

                findMatches("#ah_left", 1, 1).html(stuff)

                # TODO This timeout is necessary but if you click too fast you can
                #      end up accidentally calling the original browseAll() instead.
                setTimeout((->
                    window.browseAll = browseAllBackup
                    updateListings()
                ), 20)
            )

        # 3}}}
        button = findMatches('input#go', 1, 1)
        button.attr('type', 'button')
        button.click(->
            browseAllBackup()
        )

        setTimeout((->
            browseAllBackup()
        ), 400)

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
