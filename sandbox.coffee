if (bondButton = findMatches('img[src*="button_bond.png"]', 0, 1).length
    setTimeout(
        (-> bondButton.click()),
        randInt(FOO, BAR)
    )
