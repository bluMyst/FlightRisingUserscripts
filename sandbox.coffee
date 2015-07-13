# http://flightrising.com/main.php?p=hilo
if (new RegExp("http://flightrising\.com/main\.php.*p=hilo", 'i')).test(window.location.href)
    playAgain = findMatches('.mb_button[value="Play Again"]', 0, 1)
    if playAgain.length then playAgain.click()
