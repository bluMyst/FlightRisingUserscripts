# vim:foldmethod=marker
### UserScript options {{{1
// ==UserScript==
// @name         Ahto Library
// @description  A library of functions for use in my other scripts.
// @namespace    ahto
// @version      1.0
// @grant        none
// ==/UserScript==
###

findMatches = (selector, min=1, max=Infinity) -> # {{{1
    matches = $(selector)

    if min <= matches.length <= max
        return matches
    else
        throw Error("#{matches.length} matches (expected #{min}-#{max}) found for selector: #{selector}")

safeParseInt = (s) -> # {{{1
    n = parseInt(s)

    # Because apparently NaN != NaN...
    if isNaN(s)
        throw new Error("Unable to parse int from \"#{s}\"")
    else
        return n

safeInterval = (func, wait, times) -> # {{{1
    # Source: http://www.thecodeship.com/web-development/alternative-to-javascript-evil-setinterval/
    # Changed a bit from there.
    interv = ((w, t) ->
        return (->
            if not t? or t-- > 0
                setTimeout(interv, w)
                try
                    # This is sorta the same thing as func()
                    func.call(null)
                catch e
                    t = 0
                    #TODO: Why e.toString? Why not e?
                    throw e.toString()
        )
    )(wait, times)

    setTimeout(interv, wait)

