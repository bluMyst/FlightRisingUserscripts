HUMAN_TIMEOUT_MIN =  100
HUMAN_TIMEOUT_MAX = 1000
LOADING_WAIT      = 1000

humanTimeout = (f, extraWait=0) ->
    setTimeout f, randInt(HUMAN_TIMEOUT_MIN+extraWait, HUMAN_TIMEOUT_MAX+extraWait)

sell = (id, nListings, price, quantity=1) ->
    # BUG: quantities over 1 are untested and probably won't work.
    itemInList = findMatches("a[rel][onclick*='\\'#{id}\\'']", 1, 1)

    # Always choose the last one in the list.
    itemInList = $ itemInList[itemInList.length-1]
    itemInList.click()

    setTimeout((->
        quantityDropdown  = findMatches('select[name=qty]', 1, 1)
        durationDropdown  = findMatches('select[name=drtn]', 1, 1)
        treasurePrice     = findMatches('input[name=treas]', 1, 1)
        treasureRadio     = findMatches('input[type=radio][name=cur][value=t]', 1, 1)
        gemRadio          = findMatches('input[type=radio][name=cur][value=g]', 1, 1)
        postAuctionButton = findMatches('input[type=submit][value="Post Auction"]', 1, 1)

        # TODO: price is always in treasure for now
        treasureRadio.click()
        treasurePrice.val price.toString()
        quantityDropdown.val quantity.toString()

        # TODO: duration is always 7 days for now
        durationDropdown.val 3

        humanTimeout((->
            postAuctionButton.click()

            humanTimeout((->
                findMatches('button#yes', 1, 1).click()

                humanTimeout((->
                    findMatches('button#yes', 1, 1).click()

                    setTimeout((->
                        sell(id, nListings-1, price, quantity)
                    ), LOADING_WAIT)
                ), LOADING_WAIT)
            ), LOADING_WAIT)
        ), LOADING_WAIT)
    ), LOADING_WAIT)

    #humanTimeout -> itemInList.click()
