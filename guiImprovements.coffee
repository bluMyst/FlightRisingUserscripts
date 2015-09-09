# vim: foldmethod=marker
### UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements
// @description  Improves the interface for Flight Rising.
// @namespace    ahto
// @version      1.19.1
// @include      http://*flightrising.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=61626
// @grant        GM_getValue
// @grant        GM_setValue
// ==/UserScript==
###

### General notes {{{1
# You can catch all ajax requests with $(document).ajaxComplete(listener)
# http://api.jquery.com/ajaxcomplete/
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

# Functions and classes {{{1
exit = ->
    throw new Error 'Not an error just exiting early'

# Food value database {{{1
class PersistentObject
    constructor: (@name) ->
        @object = JSON.parse(
            GM_getValue(@name) or '{}'
        )

    save: ->
        GM_setValue(@name, JSON.stringify(@object))

    set: (key, value) ->
        if @object[key] != value
            @object[key] = value
            @save()

    get: (key) ->
        return @object[key]

foodDB = new PersistentObject('foodDB')

$(document).ajaxComplete((event, jqXHR, ajaxOptions) ->
    if /includes\/itemajax\.php/.test(ajaxOptions.url)
        parsedHTML = $.parseHTML jqXHR.responseText

        foodValue = /Food Points: (\d+)/.exec(jqXHR.responseText)
        name = $(parsedHTML[0]).find('div:nth-child(1) > div:nth-child(1)').text()

        if foodValue
            console.log 'Item is food!', foodValue
            foodValue = parseInt(foodValue[1])
            console.log "Food value of #{name}:", foodValue
            foodDB.set(name, foodValue)

            # NOTE: Object.keys only works in ECMAScript >=5
            console.log "foodDB now contains #{Object.keys(foodDB.object).length} items."
    else
        console.log 'Ignored AJAX request for:', ajaxOptions.url
)

class UsersubscriptHandler # {{{2
    ###
    # Handles 'usersubscripts', like a userscript but embedded in this bigger
    # userscript. Another way to think about it is, this object runs certain
    # functions if certain associated regexes match.
    ###
    constructor: () ->
        @scripts = []

    register: (regex, func) ->
        if typeof regex == 'string'
            regex = new RegExp(regex)

        @scripts.push({regex:regex, func:func})

    think: () ->
        for script in @scripts
            if script.regex.test window.location.href
                script.func()

class FormData # {{{2
    constructor: (@form) ->

    field: (name, newValue) ->
        # pass no newValue to get current value.
        field = @form.find "[name=#{name}]"

        if newValue
            return field.val(newValue)
        else
            return field.val()

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
scriptHandler = new UsersubscriptHandler()

# Baldwin's Bubbling Brew {{{2
baldwinsBubblingBrew = ->
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

    if (new RegExp('/baldwin/create')).test(window.location.href)
        bubble   = findMatches('.baldwin-create-speech-bubble', 1, 1)
        instruct = findMatches('.baldwin-create-instruct', 1, 1)

        bubble.css('padding', '5px').css('right', 'inherit')
        instruct.css('background', 'inherit')
        bubble.html BBB_GUIDE

scriptHandler.register(
    new RegExp('http://www1\.flightrising\.com/trading/baldwin.*', 'i'),
    baldwinsBubblingBrew
)

# Marketplace {{{2
marketplace = ->
    for price in findMatches('#market > div > div:nth-child(3) > div:nth-child(4)', 1)
        price = $(price)
        price.text(
            numberWithCommas safeParseInt price.text()
        )

scriptHandler.register(
    new RegExp('http://flightrising\.com/main\.php.*p=market', 'i'),
    marketplace
)

# HiLo Game {{{2
hiloGame = ->
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

scriptHandler.register(
    new RegExp("http://flightrising\.com/main\.php.*p=hilo", 'i'),
    hiloGame,
)
# Lair (for auto-bond) {{{2
lair = ->
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
    else if findMatches('img[src*="button_bond_inactive.png"]', 0, 1).length
        document.title = 'Bonded!'

scriptHandler.register(
    new RegExp("http://flightrising\.com/main\.php.*p=lair", 'i'),
    lair,
)

# Auction House {{{2
auctionHouse = ->
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

            @foodValue    = foodDB.get(@name)
            @pricePerFood = @price / (@foodValue * @numberOfItems)

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

            priceString = numberWithCommas @price

            # TODO: Clean this code up.
            # TODO: Code breaks on certain tab switches, lasts until refresh.
            if @foodValue
                pricePerFoodString = numberWithCommas Math.round @pricePerFood
                target.textContent = " #{priceString} (#{pricePerFoodString}/fp)"
            else if @numberOfItems > 1
                priceEAString = numberWithCommas Math.round @priceEA
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

            # TODO: Is it faster to do this always or to check if .notEmpty() first?
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

        browseAllBackup = window.browseAllBackup = window.browseAll = (args...) -> # {{{5
            console.log 'hacked browseAll called with', args
            # tl = treasure low  gh = gems high
            # Arguments are:
            # tab, page, [maybe cat], [lohi], [maybe name], ordering, direct
            # lohi = [treasure lohi] or [gem lohi] or [nothing]
            # X lohi = X hi or X lo or (X lo, X hi)

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
                    console.log "browseAll overwritten"
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

        # Changing submit button from being type=submit to type=input means that
        # pressing enter on any part of the form will no longer auto-submit.
        # So this is a workaround.
        findMatches('form#searching input[type=text]').keydown((e) ->
            if !e then e = window.event # TODO: no idea what this is for
            if e.keyCode == 13 then button.click()
        )

        # Add an 'update formatting' button, since my code can't be trusted to
        # figure that kinda stuff out on its own apparently.
        # #go is the submit button
        updateButton = $('''
            <input type=button value="Update formatting" class=mb_button>
        ''')

        updateButton.click(->
            window.browseAll = window.browseAllBackup = browseAllBackup
            updateListings()
        )

        findMatches('#go', 1, 1).after(updateButton)

        setTimeout((->
            browseAllBackup()
        ), 400)

    # }}}3
scriptHandler.register(
    new RegExp('http://flightrising\.com/main\.php.*p=ah', 'i'),
    auctionHouse,
)

# }}}2
scriptHandler.think()
