# vim: foldmethod=marker
### UserScript info {{{1
// ==UserScript==
// @name        Flight Rising HiLo
// @description Automatically plays the HiLo game for you.
// @version     1.0
// @namespace   ahto
// @include     http://flightrising.com/main.php*p=hilo*
// @require     https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js
// @grant       none
// ==/UserScript==
###

# Card hashes {{{1
# hashes confirmed to stay the same each time, even after a full day
# There are no 1 or 13 cards on the known side.
cards =
    2 :  1892593725
    3 :   745232701
    4 :   343619172
    5 :  -932029944
    6 :  1865291602
    7 : -1248784561
    8 :   781610367
    9 :  1741550947
    10:  -974252486
    11:   376369066
    12: -1855727273

setRandomTimeout = (f, min=500, max=1500) -> # {{{1
    setTimeout(f, randInt(min, max))

delayClick = (target) -> # {{{1
    setRandomTimeout((-> target.click()), 500, 1500)

# The rest of the code {{{1
playAgain = findMatches('.mb_button', 0, 1)

if playAgain.length == 1
    console.log('Play again button detected; clicking.')
    delayClick(playAgain)
    return

timeRemaining = findMatches('#super-container > div:nth-child(3) > div:nth-child(1) > span:nth-child(2)', 0, 1)

if timeRemaining.length == 1
    console.log "Out of guesses."
    # TODO Figure out how to exit the program early.

    ###
    timeRemaining = timeRemaining.innerHTML.match(/(\d+) minutes/)[1]
    console.log "Detected time remaining of #{timeRemaining} minutes."
    timeRemaining++ # assume the number of minutes is rounded down

    # convert from minutes to milliseconds
    timeRemaining = Math.floor( timeRemaining * 1000 * 60 )

    setRandomTimeout(
        (-> alert "Reload the page to play HiLo again."),
        timeRemaining,
        timeRemaining+5000
    )
    ###

# TODO Rework this canvas-making code to use jQuery.
canvas   = document.createElement('canvas')
leftCard = $('#super-container > div:nth-child(3) > img:nth-child(1)')[0]
lo       = $('#super-container > div:nth-child(3) > div:nth-child(4) > map:nth-child(3) > area:nth-child(1)')[0]
hi       = $('#super-container > div:nth-child(3) > div:nth-child(4) > map:nth-child(3) > area:nth-child(2)')[0]

[canvas.width, canvas.height] = [leftCard.width, leftCard.height]
console.log "Canvas width x height: #{canvas.width}x#{canvas.height}"
findMatches('.main', 1, 1)[0].appendChild(canvas)
ctx = canvas.getContext('2d')

# imageLoop defined and called {{{1
imageLoop = (loops) ->
    if loops == undefined
        loops = 0

    ctx.drawImage(leftCard, 0, 0)

    hash = stringHashCode( canvas.toDataURL("image/png") )

    for referenceCardNum, referenceHash of cards
        if hash == referenceHash
            cardNum = referenceCardNum
            console.log "Card identified as #{cardNum}"
            break

    if cardNum != undefined
        # 5% chance of failure
        if Math.random() <= 0.05
            console.log 'Decided to fail on purpose this time.'
            [onLo, onHi] = [hi, lo]
        else
            [onLo, onHi] = [lo, hi]

        if cardNum > 13/2
            console.log 'Best decision is to click lo'
            delayClick(onLo)
        else
            console.log 'Best decision is to click hi'
            delayClick(onHi)
    else
        DELAY     = 2000
        MAX_LOOPS = 10

        console.log "Failed to identify card with hash: #{hash}"

        if loops < MAX_LOOPS
            console.log "[#{loops+1}/#{MAX_LOOPS}] Looping in #{DELAY} ms..."
            setTimeout( (-> imageLoop(loops+1)), DELAY )
            return
        else
            throw new Error "Failed to identify card with hash: #{hash}"

imageLoop()
