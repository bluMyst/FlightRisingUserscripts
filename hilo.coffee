# vim: foldmethod=marker
# This is broken, don't bother with it. Every browser, and possibly every computer,
# will give you a different image hash.
### UserScript info {{{1
// ==UserScript==
// @name        Flight Rising HiLo
// @description Automatically plays the HiLo game for you.
// @version     1.0
// @namespace   ahto
// @include     http://flightrising.com/main.php*p=hilo*
// @require     https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=61510
// @grant       none
// ==/UserScript==
###

# Settings {{{1
# 0.05 would be a 5% chance.
FAILURE_CHANCE = 0.05

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

exit = -> # {{{1
    throw new Error 'Not really an error just stopping execution.'

# hashImage {{{1
canvas = $('<canvas>')
findMatches('.main', 1, 1).append(canvas)
ctx = canvas[0].getContext('2d')

hashImage = (img) ->
    canvas.width  img.width()
    canvas.height img.height()

    ctx.drawImage(img[0], 0, 0)

    hash = stringHashCode( canvas[0].toDataURL("image/png") )

    console.log "Hash: #{hash}"
    console.log canvas[0].toDataURL('image/png')
    # TODO Figure out why this differs between browsers.
    return hash

# The rest of the code {{{1
playAgain = findMatches('.mb_button[value="Play Again"]', 0, 1)
if (playAgain).length
    console.log('Play again button detected; clicking.')
    delayClick(playAgain)
    exit()

timeRemaining = findMatches('div[style*="background-image:url(../images/layout/trunk.png)"] > div > span', 0, 1)
if timeRemaining.length
    console.log "Out of guesses."
    exit()

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

leftCard = findMatches('img[src*="image_generators/hilo_img.php"]', 1, 1)
lo       = findMatches('area[href="main.php?p=hilo&choice=lo"]', 1, 1)
hi       = findMatches('area[href="main.php?p=hilo&choice=hi"]', 1, 1)

(imageLoop = (loops=0) -> # {{{1
    hash = hashImage leftCard

    for referenceCardNum, referenceHash of cards
        if hash == referenceHash
            cardNum = referenceCardNum
            console.log "Card identified as #{cardNum}"
            break

    ###
    if cardNum?
        if Math.random() <= FAILURE_CHANCE
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
    ###
)() # <--- Hey notice this part it's important.
