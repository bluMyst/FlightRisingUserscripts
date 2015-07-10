timer = $('#baldwin-timer-value')[0]

getTimerValue = ->
    timer.getAttribute('data-seconds-left')

interval = setInterval((->
    if getTimerValue() <= 0
        document.title = 'DONE!'
        cancelInterval(interval)
), 10000)
