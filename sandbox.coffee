CLICK_TIMEOUT_MIN =  300
CLICK_TIMEOUT_MAX = 1000

if (bondButton = findMatches('img[src*="button_bond.png"]', 0, 1)).length
    setTimeout(
        (-> bondButton.click()),
        randInt(CLICK_TIMEOUT_MIN, CLICK_TIMEOUT_MAX)
    )
