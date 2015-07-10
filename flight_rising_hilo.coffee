###
// ==UserScript==
// @name        Flight Rising HiLo
// @namespace   ahto
// @include     http://flightrising.com/main.php*p=hilo*
// @version     1.0
// @grant       none
// ==/UserScript==
###

String.prototype.hashCode = ->
    hash = 0

    for i in this
        chr   = i.charCodeAt(0)
        hash  = ((hash << 5) - hash) + chr
        hash |= 0; # Convert to 32bit integer

    return hash

randInt = (min, max) ->
    min + Math.floor(Math.random() * (max+1-min))

setRandomTimeout = (f, min, max) ->
    setTimeout(f, randInt(min, max))

delayClick = (target) ->
    setRandomTimeout((-> target.click()), 500, 1500)

# hashes confirmed to stay the same each time, even after a full day
cards =
    1:   undefined
    2:   1892593725
    3:   745232701
    4:   343619172
    5:   -932029944
    6:   1865291602
    7:   -1248784561
    8:   781610367
    9:   1741550947
    10:  -974252486
    11:  376369066
    12:  -1855727273
    13:  undefined

playAgain = $('.mb_button')[0]

if playAgain != undefined
    console.log('Play again button detected; clicking.')
    delayClick(playAgain)
    return

timeRemaining = $('#super-container > div:nth-child(3) > div:nth-child(1) > span:nth-child(2)')[0]

if timeRemaining != undefined
    console.log "Out of guesses."

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

canvas   = document.createElement('canvas')
leftCard = $('#super-container > div:nth-child(3) > img:nth-child(1)')[0]
lo       = $('#super-container > div:nth-child(3) > div:nth-child(4) > map:nth-child(3) > area:nth-child(1)')[0]
hi       = $('#super-container > div:nth-child(3) > div:nth-child(4) > map:nth-child(3) > area:nth-child(2)')[0]

[canvas.width, canvas.height] = [leftCard.width, leftCard.height]
console.log "Canvas width x height: #{canvas.width}x#{canvas.height}"
$('.main')[0].appendChild(canvas)
ctx = canvas.getContext('2d')

imageLoop = (loops) ->
    if loops == undefined
        loops = 0

    ctx.drawImage(leftCard, 0, 0)

    hash = canvas.toDataURL("image/png").hashCode()

    for referenceCardNum, referenceHash of cards
        if hash == referenceHash
            cardNum = referenceCardNum
            console.log "Card identified as #{cardNum}"
            break

    if cardNum != undefined
        #TODO: Make low random chance of failure.
        if cardNum > 13/2
            console.log 'Clicking lo button.'
            delayClick(lo)
        else
            console.log 'Clicking hi button.'
            delayClick(hi)
    else
        DELAY = 2000
        MAX_LOOPS = 10
        console.log "Failed to identify card with hash: #{hash}"
        if loops < MAX_LOOPS
            console.log "[#{loops+1}/#{MAX_LOOPS}] Looping in #{DELAY} ms..."
            setTimeout( (-> imageLoop loops+1), DELAY )
            return
        else
            console.log "Max tries exceeded. Giving up and alerting the user."
            alert "Failed to identify card with hash: #{hash}"

imageLoop()
