# vim: foldmethod=marker
### UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements
// @description  Improves the interface for Flight Rising.
// @namespace    ahto
// @version      1.24.0
// @include      http://*flightrising.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=75750
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

Mail:
- Auto-collects attachments.
- Selecting a message for deletion highlights the whole thing.
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

# Min and max times to wait before clicking a button (among other things).
HUMAN_TIMEOUT_MIN =  300
HUMAN_TIMEOUT_MAX = 1000

BBB_BLINK_TIMEOUT = 500

# Timeout to wait for something to load. Used all over the place.
LOADING_WAIT = 1000

# Functions and classes {{{1
setHumanTimeout = (f, extraTime=0) -> # {{{2
    wait_time = randInt(
        HUMAN_TIMEOUT_MIN + extraTime,
        HUMAN_TIMEOUT_MAX + extraTime,
    )

    return setTimeout_(wait_time, f)

getItemTooltip = (id, tab, callback) ->
    $.get('/includes/itemajax.php', {id:id, food:food}).done callback

getItemDetails = (id, tab, callback) ->
    getItemTooltip id, tab, (results) ->
        # TODO: Add rarity and description and category.
        results        = $ results
        nameStyle      = "color:#731d08; font-weight:bold; font-size:11px;"
        foodPointStyle = "color:#000; font-size:10px; position:absolute; bottom:5px; right:5px; font-weight:bold;"
        sellValueStyle = "color:#000; font-size:10px; position:absolute; bottom:5px; font-weight:bold;"

        info =
            name:       results.find("div[style='#{nameStyle     }']").text()
            sellValue:  results.find("div[style='#{sellValueStyle}']").text()
            foodPoints: if (r = results.find("div[style='#{foodPointStyle}']")).length then r.text()

        callback info

class FormData # {{{2
    constructor: (@form) ->

    field: (name, newValue) ->
        # pass no newValue to get current value.
        field = @form.find "[name=#{name}]"

        if newValue
            return field.val(newValue)
        else
            return field.val()

class AuctionSearch # {{{2
    GET_NUMBER: /[0-9]+/

    constructor: (@postData) ->
        ###
        # cat means category, tl means treasure low, gh means gems high. tab,
        # page (but this is auto-sent), cat, tl, th, gl, gh, name, ordering,
        # direct. Ordering can be 'expiration' or 'cost'. All values are
        # strings. direct (direction) can be 'ASC' or 'DESC'. Valid categories
        # are 'mats', 'app', 'dragons', 'fam', 'battle', 'skins', and 'other'.
        ###
        @sales = []

        if      @postData.direct   not in ['ASC', 'DESC'] or
                @postData.ordering not in ['expiration', 'cost'] or
                @postData.cat not in [
                    'mats', 'app', 'dragons', 'fam', 'battle', 'skins', 'other'
                ]
            throw new Error 'Invalid postData.'

        $.post("includes/ah_buy_#{tab}.php", @postData).done (response) =>
            # TODO: Get number of pages then addResponse for every one of them.
            response = $ response
            pageHolderStyle = "font-size:12px; text-align:center; position:absolute; bottom:5px; height:27px; width:480px;"
            pages = parseInt response.find("div[style='#{pageHolderStyle}'] a[style='cursor:pointer;']:last").text()

            @addResponse response
            # TODO: Make a recursive function with setHumanTimeout delays to get all the results.
            #for pageNum in [2..pages]

    addResponse: (@response) ->
        console.log 'setResponse called on', @response
        getNumber = (string) -> parseInt GET_NUMBER.exec(string)[0]

        sales = $ 'div[id^=sale]'

        for sale in sales
            saleInfo =
                saleID:      getNumber sale.attr 'id'
                itemID:      getNumber sale.find('img[src^="/images/cms/trinket/"').attr 'src'
                quantity:    parseInt sale.find('span[style="position:absolute; bottom:0px; left:0px; background-color:#FFF; color:#731d08; font-size:11px; font-weight:bold; padding-right:2px; width:15px; height:10px; text-align:right;"]').text()
                # expiration is the number of seconds since the unix epoch
                expiration:  getNumber sale.find('span[time]').attr 'time'
                price:       getNumber sale.find('div[id^=buy_button]').text()

                currency: if sale.find('img[src$=icon_gems.png]').length
                    GEMS
                else if sale.find('img[src$=icon_treasure.png]').length
                    TREASURE
                else
                    undefined

            saleInfo.priceEA = saleInfo.price / saleInfo.quantity
            sales.push saleInfo
            console.log sale
            console.log saleInfo

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

# Usersubscripts {{{1
# Baldwin's Bubbling Brew {{{2
if urlMatches new RegExp('http://www1\.flightrising\.com/trading/baldwin.*', 'i')
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
            document.title = 'Ready!'

    # Create tab {{{3
    if urlMatches new RegExp('/baldwin/create', 'i')
        bubble   = findMatches('.baldwin-create-speech-bubble', 1, 1)
        instruct = findMatches('.baldwin-create-instruct', 1, 1)

        bubble.css('padding', '5px').css('right', 'inherit')
        instruct.css('background', 'inherit')
        bubble.html BBB_GUIDE

    # Transmute tab {{{3
    if urlMatches new RegExp('/baldwin/transmute', 'i')
        info = findMatches('.baldwin-cauldron-status', 0, 1)

        # If there's nothing being transmuted, preserving the HTML causes the transmute button
        # not to work for some reason, so if that's the case we'll just change nothing and move on.
        if info.length
            bubble = findMatches('#speech-bubble-content', 1, 1)
            bubble.contents().remove()
            bubble.html BBB_GUIDE
            bubble.append(info)

# Marketplace {{{2
if urlMatches new RegExp('http://flightrising\.com/main\.php.*p=market', 'i')
    for price in findMatches('#market > div > div:nth-child(3) > div:nth-child(4)', 1)
        price = $(price)
        price.text(
            numberWithCommas safeParseInt price.text()
        )

# HiLo Game {{{2
if urlMatches new RegExp("http://flightrising\.com/main\.php.*p=hilo", 'i')
    guesses = parseInt(
        findMatches(
            '#super-container > div:nth-child(2) > div:nth-child(4) > div:nth-child(2)',
            1, 1,
        ).text()
    )

    if guesses > 0
        playAgain = findMatches('.mb_button[value="Play Again"]', 0, 1)
        if playAgain.length
            setHumanTimeout -> playAgain.click()
        else
            # Add keyboard shortcut instructions in place of the normal useless ones.
            findMatches('#super-container > div:nth-child(3) > div:nth-child(3)', 1, 1).html(
                '''
                Press <b>j (lower)</b> or <b>k (higher)</b>, or use the buttons on the left.<br>
                If you guess correctly, you'll win 65 treasure (as of 2015.09.10).
                '''
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

# Lair (for auto-bond) {{{2
if urlMatches new RegExp("http://flightrising\.com/main\.php.*p=lair", 'i')
    if (bondButton = findMatches('img[src*="button_bond.png"]', 0, 1)).length
        setHumanTimeout ->
            bondButton.click()

            setHumanTimeout ->
                findMatches('button#no', 1, 1).click()
    else if findMatches('img[src*="button_bond_inactive.png"]', 0, 1).length
        if $('img[src*="bar_bond_max.png"]').length
            document.title = 'Awakened!'
        else
            document.title = 'Bonded!'

# Auction House Buy {{{2
if urlMatches new RegExp('http://flightrising\.com/main\.php.*p=ah', 'i')
    if findMatches('input[value=Search]', 0, 1).length
        class AuctionListing # {{{3
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
                if not target?
                    console.warn("Tried to modifyElement() for #{@name} @ #{@price} but the auction expired(?).")
                    return

                if not safeParseInt(target.textContent) == @price
                    throw new Error("Tried to modify an auction house item but the price didn't match expectations.")

                priceString   = numberWithCommas @price
                priceEAString = numberWithCommas Math.round @priceEA

                if @numberOfItems > 1
                    target.textContent = " #{priceString} (#{priceEAString} ea)"
                else
                    target.textContent = " #{priceString}"

                # Give the new text some breathing room.
                @button.css('width', AH_BUTTON_SPACING)

                @nameElement.html(
                    "<a href='javascript:$(\"input[name=name]\").val(\"#{@name}\")'>#{@name}</a>"
                )

        getTab = -> #{{{3
            if (tab = /[?&]tab=([^&]+)/.exec(window.location.href))?
                tab = tab[1]
            else
                tab = 'food'

            if not tab in ['food', 'mats', 'app', 'dragons', 'fam', 'battle', 'skins', 'other']
                throw new Error "Detected tab as invalid option #{postData.tab.toString()}."

            return tab

        # Filter by only gems or only treasure {{{3
        class CurrencyFields # {{{4
            constructor: (@img, @low, @high) ->

            notEmpty: () ->
                val = @low.val().length or @high.val().length
                return val

        class CurrencyFilterer # {{{4
            LOW:  '0'
            HIGH: '999999999999999999'

            constructor: (@searchButton, @treasureFields, @gemFields) ->
                @treasureListener = @makeListener(@treasureFields, @gemFields)
                @gemListener      = @makeListener(@gemFields, @treasureFields)

            makeListener: (us, them) -> (event) =>
                if us.notEmpty()
                    us.low.val  ''
                    us.high.val ''
                else
                    us.low.val  @LOW
                    us.high.val @HIGH

                them.low.val  ''
                them.high.val ''

            init: ->
                @treasureFields.img.click @treasureListener
                @gemFields.img.click      @gemListener

                # Make the currency buttons look clickable by changing the cursor when you
                # hover over them.
                @treasureFields.img.css 'cursor', 'pointer'
                @gemFields.img.css      'cursor', 'pointer'

                if AH_DEFAULT_CURRENCY?
                    filterer.showOnly AH_DEFAULT_CURRENCY

            showOnly: (currency) ->
                switch currency
                    when TREASURE
                        @treasureListener()
                    when GEMS
                        @gemListener()
                    else
                        throw new Error "CurrencyFilterer.showOnly called with invalid currency: #{currency}"

                @searchButton.click()

        filterer = new CurrencyFilterer( # {{{4
            # Search button
            findMatches('input[value=Search]', 1, 1).click()

            # Treasure
            new CurrencyFields(
                findMatches('#searching img[src="/images/layout/icon_treasure.png"]', 1, 1),
                findMatches('input[name=tl]', 1, 1),
                findMatches('input[name=th]', 1, 1),
            ),

            # Gems
            new CurrencyFields(
                findMatches('#searching img[src="/images/layout/icon_gems.png"]', 1, 1),
                findMatches('input[name=gl]', 1, 1),
                findMatches('input[name=gh]', 1, 1),
            ),
        )

        filterer.init()

        if getTab() != 'dragons' # {{{3
            # Add a clear button for item name and put it right above the textbox. {{{4
            itemNameText = $('#searching > div:nth-child(1)')
            itemNameText.html(
                itemNameText.html() +
                '''
                    <a href='javascript:$("input[name=name").val("")'>
                        &nbsp;(clear)
                    </a>
                '''
            )

            # Modify AH listings {{{4
            updateListings = ->
                listings = (new AuctionListing( $(i) ) for i in $('#ah_left div[id*=sale]'))
                i.modifyElement() for i in listings

            updateListings()

            # Overwrite browseAll() and change submit button {{{4
            form = new FormData findMatches('form#searching', 1, 1)

            browseAllBackup = window.browseAll = (args...) -> # {{{5
                console.log 'browseAll called with', args
                # tl = treasure low  gh = gems high
                # Arguments are:
                # tab, page, [maybe cat], <lohi>, [maybe name], ordering, direct
                # lohi = <treasure lohi> or <gem lohi> or <nothing>
                # treasure lohi = th, tl
                # gem lohi = gh, gl

                # Build postData {{{6
                postData = {}

                [
                    postData.tab,
                    postData.page,
                    ...,
                    postData.ordering,
                    postData.direct,
                ] = args

                if not postData.page?
                    # If you search for something with < your current number of
                    # pages, you end up with a blank page even though there are
                    # results to be seen.
                    postData.page = 1
                    ###
                    m = findMatches('#ah_left > div:nth-child(3) > span', 0, 1)

                    if m.length
                        postData.page = m.text()
                    else
                        console.log 'No page element found, assuming only 1 page.'
                        postData.page = '1'
                    ###

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

                if (cat = form.field 'cat')
                    postData.cat = cat

                if (name = form.field 'name')
                    postData.name = name

                tl = form.field 'tl'
                th = form.field 'th'
                gl = form.field 'gl'
                gh = form.field 'gh'

                tll = if tl then tl.length else 0
                thl = if th then th.length else 0
                gll = if gl then gl.length else 0
                ghl = if gh then gh.length else 0

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

                # }}}6
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
                    ), 100)
                )

            # Modify submit button {{{5
            button = findMatches('input#go', 1, 1)
            button.attr('type', 'button')
            button.click(->
                browseAllBackup()
            )

            # }}}5
            setTimeout((->
                browseAllBackup()
            ), 400)

            # Enter to submit inputs {{{4
            # Changing submit button from being type=submit to type=input means that
            # pressing enter on any part of the form will no longer auto-submit.
            # So this is a workaround.
            findMatches('form#searching input[type=text]').keydown((e) ->
                if e.keyCode == 13 then button.click()
            )

            # Update formatting button {{{4
            # Add an 'update formatting' button, since my code can't be trusted to
            # figure that kinda stuff out on its own apparently.
            # #go is the submit button
            buttonTitle = '''
                Tells the userscript to update formatting (show price ea and other information)
                on this page, since the code for doing that automatically has a tendency to
                forget.
            '''

            updateButton = $("""
                <input type=button value="Update formatting" title="#{buttonTitle}" class=mb_button>
            """)

            updateButton.click(->
                window.browseAll = window.browseAllBackup = browseAllBackup
                updateListings()
            )

            findMatches('#go', 1, 1).after(updateButton)

# Auction House Sell {{{2
if urlMatches new RegExp('flightrising\.com/main\.php.*action=sell', 'i')
    sell = window.sell = (id, nListings, price, quantity=1) ->
        if nListings <= 0 then return

        # TODO: If quantity * nListings > number of items, stuff will break
        #       so find a way to test for proper quantity before submitting.
        itemInList = $("a[rel][onclick*='\\'#{id}\\'']")

        # Always start with the last one in the list.
        itemInList = $ itemInList[itemInList.length-1]
        itemInList.click()

        setTimeout((->
            quantityDropdown  = $('select[name=qty]')
            durationDropdown  = $('select[name=drtn]')
            treasurePrice     = $('input[name=treas]')
            treasureRadio     = $('input[type=radio][name=cur][value=t]')
            gemRadio          = $('input[type=radio][name=cur][value=g]')
            postAuctionButton = $('input[type=submit][value="Post Auction"]')

            # TODO: price is always in treasure for now
            treasureRadio.click()
            treasurePrice.val price.toString()
            quantityDropdown.val quantity

            # TODO: duration is always 7 days for now
            durationDropdown.val 3

            setHumanTimeout((->
                postAuctionButton.click()

                setHumanTimeout((->
                    $('button#yes').click()

                    setHumanTimeout((->
                        $('button#yes').click()

                        setHumanTimeout((->
                            sell(id, nListings-1, price, quantity)
                        ), LOADING_WAIT)
                    ), LOADING_WAIT)
                ), LOADING_WAIT)
            ), LOADING_WAIT)
        ), LOADING_WAIT)

# Message (auto-collect) {{{2
if urlMatches new RegExp('http://www1\.flightrising\.com/msgs/[0-9]+', 'i')
    setHumanTimeout ->
        findMatches('button#take-items', 1, 1).click()

        setHumanTimeout ->
            findMatches('button#confirm', 1, 1).click()
            document.title = 'Collected!'

# Messages list (auto-collect all) {{{2
if new RegExp('http://www1\.flightrising\.com/msgs$', 'i').test document.location.href
    autoCollectAll = window.autoCollectAll = ->
        # TODO This also detects the icon_treasure.png at the top of the page.
        links = $('img[src$="attachment.png"], img[src$="icon_treasure.png"]').parents('tr').find('a[href*="msgs"]')

        for i in ($ i for i in links)
            window.open i.attr 'href'

    $('#ajaxbody').append """
        <input type=button class="beigebutton thingbutton" id=autoCollectButton value="Auto-collect all.">
    """

    $('#autoCollectButton').click -> autoCollectAll()
