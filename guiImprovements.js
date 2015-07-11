// Generated by CoffeeScript 1.9.3

/* UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements
// @description  Improves the interface for Flight Rising.
// @namespace    ahto
// @version      1.6
// @include      http://*flightrising.com/*
// @grant        none
// ==/UserScript==
 */


/* Features and changes {{{1
- Removes redundant links to messages and gems.
- Adds two new links to Baldwin's Bubbling Brew.
- Flashes the title of Baldwin's Bubbling Brew when your brew is ready.
- At the Auction House, clicking the icons next to price ranges will let you sort by only treasure or only gems.
- Tells you how much items cost each at the auction house.
 */

(function() {
  var AuctionListing, BLINK_TIMEOUT, GEMS, TREASURE, blinker, findMatches, gems, listener, listings, safeInterval, safeParseInt, treasure;

  findMatches = function(selector, min, max) {
    var matches, ref;
    if (min == null) {
      min = 1;
    }
    if (max == null) {
      max = Infinity;
    }
    matches = $(selector);
    if ((min <= (ref = matches.length) && ref <= max)) {
      return matches;
    } else {
      throw Error(matches.length + " matches (expected " + min + "-" + max + ") found for selector: " + selector);
    }
  };

  safeParseInt = function(s) {
    var n;
    n = parseInt(s);
    if (isNaN(s)) {
      throw new Error("Unable to parse int from \"" + s + "\"");
    } else {
      return n;
    }
  };

  safeInterval = function(func, wait, times) {
    var interv;
    interv = (function(w, t) {
      return (function() {
        var e;
        if ((t == null) || t-- > 0) {
          setTimeout(interv, w);
          try {
            return func.call(null);
          } catch (_error) {
            e = _error;
            t = 0;
            throw e.toString();
          }
        }
      });
    })(wait, times);
    return setTimeout(interv, wait);
  };

  findMatches('a.navbar[href=\'main.php?p=pm\'],\na.navbar[href*=\'msgs\'],\na.navbar[href=\'main.php?p=ge\'],\na.navbar[href*=\'buy-gems\']', 2, 2).remove();

  findMatches("a.navbar[href*=crossroads]").after('<a class=\'navbar navbar-glow-hover\' href=\'http://www1.flightrising.com/trading/baldwin/transmute\'>\n    Alchemy (Transmute)\n</a>\n<a class=\'navbar navbar-glow-hover\' href=\'http://www1.flightrising.com/trading/baldwin/create\'>\n    Alchemy (Create)\n</a>');

  if (/http:\/\/www1.flightrising.com\/trading\/baldwin.*/i.test(window.location.href)) {
    BLINK_TIMEOUT = 250;
    if (findMatches("input[value='Collect!']", 0, 1).length !== 0) {
      blinker = setInterval((function() {
        if (document.title === 'Ready!') {
          return document.title = '!!!!!!!!!!!!!!!!';
        } else {
          return document.title = 'Ready!';
        }
      }), BLINK_TIMEOUT);
      window.onfocus = function() {
        clearInterval(blinker);
        return document.title = 'Done.';
      };
    }
  } else if (/http:\/\/flightrising\.com\/main\.php\?.*p=ah.*/.test(window.location.href)) {
    TREASURE = 0;
    GEMS = 1;
    AuctionListing = (function() {
      function AuctionListing(element) {
        this.element = element;
        this.numberOfItems = safeParseInt(this.element.find('div:nth-child(1) > span:nth-child(1) > span').text());
        this.button = this.element.find('[id*=buy_button]');
        if (this.button.find('img[src="/images/layout/icon_gems.png"]')) {
          this.currency = GEMS;
        } else if (this.button.find('img[src="/images/layout/icon_treasure.png"]')) {
          this.currency = TREASURE;
        } else {
          throw new Error("Unable to find currency for an auction house item.");
        }
        this.price = safeParseInt(this.button.text());
        this.priceEA = this.price / this.numberOfItems;
      }

      AuctionListing.prototype.modifyElement = function() {
        var target;
        if (this.numberOfItems > 1) {
          target = this.button[0].childNodes[2];
          if (target == null) {
            return;
          }
          if (!safeParseInt(target.textContent) === this.price) {
            throw new Error("Tried to modify an auction house item but the price didn't match expectations.");
          }
          target.textContent = " " + this.price + " (" + (Math.round(this.priceEA)) + " ea)";
        }
        return this.button.css('width', '150px');
      };

      return AuctionListing;

    })();
    listings = void 0;
    safeInterval((function() {
      var i, isUpdated, j, len, new_listings, results;
      new_listings = $('#ah_left div[id*=sale]');
      isUpdated = (function() {
        var i, j, ref;
        if (listings == null) {
          return true;
        }
        if (new_listings.length === 0 || listings.length === 0) {
          return false;
        }
        for (i = j = 0, ref = listings.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
          if (listings[i].element[0] !== new_listings[i]) {
            return true;
          }
        }
        return false;
      })();
      if (isUpdated) {
        listings = (function() {
          var j, len, ref, results;
          ref = $('#ah_left div[id*=sale]');
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            i = ref[j];
            results.push(new AuctionListing($(i)));
          }
          return results;
        })();
        results = [];
        for (j = 0, len = listings.length; j < len; j++) {
          i = listings[j];
          results.push(i.modifyElement());
        }
        return results;
      }
    }), 2000);
    treasure = {
      img: findMatches('#searching img[src="/images/layout/icon_treasure.png"]', 1, 1),
      low: findMatches('input[name=tl]', 1, 1),
      high: findMatches('input[name=th]', 1, 1)
    };
    gems = {
      img: findMatches('#searching img[src="/images/layout/icon_gems.png"]', 1, 1),
      low: findMatches('input[name=gl]', 1, 1),
      high: findMatches('input[name=gh]', 1, 1)
    };
    listener = function(event) {
      var ref, ref1, them, us;
      if (event.currentTarget === treasure.img[0]) {
        ref = [treasure, gems], us = ref[0], them = ref[1];
      } else if (event.currentTarget === gems.img[0]) {
        ref1 = [gems, treasure], us = ref1[0], them = ref1[1];
      } else {
        throw new Error('Something went wrong with the auction house code.');
      }
      if (us.low.val() !== '' || us.high.val() !== '') {
        us.low.val('');
        us.high.val('');
      } else {
        us.low.val('0');
        us.high.val('99999999999999999999');
      }
      if (them.low.val() !== '' || them.high.val() !== '') {
        them.low.val('');
        return them.high.val('');
      }
    };
    treasure.img.click(listener);
    gems.img.click(listener);
  }

}).call(this);
