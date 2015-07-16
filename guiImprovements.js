// Generated by CoffeeScript 1.9.3

/* UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements
// @description  Improves the interface for Flight Rising.
// @namespace    ahto
// @version      1.13.0
// @include      http://*flightrising.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=61626
// @grant        none
// ==/UserScript==
 */

/* Features and changes {{{1
General:
- Adds two new links to Baldwin's Bubbling Brew.
- Removes redundant links to messages and gems.
- Amount of treasure has commas in it.
- Automatically clicks 'play again' at the HiLo game.

Auction House:
- Clicking the icons next to price ranges will let you sort by only treasure or only gems.
- Tells you how much items cost per unit.
- Adds a clear item name button.
- Clicking an item's name sets that to the name filter.
- Prices have commas in them.

Baldwin's Bubbling Brew:
- Replaces useless dialog text with a handy guide.
- Flashes title when your brew is ready. (Leave BBB running in a background tab)
 */
var AH_BUTTON_SPACING, AH_DEFAULT_CURRENCY, AH_UPDATE_DELAY, AuctionListing, BBB_BLINK_TIMEOUT, BBB_GUIDE, FormData, GEMS, HILO_CLICK_MAX, HILO_CLICK_MIN, TD_ATTR, TREASURE, blinker, browseAllBackup, bubble, button, currentTreasure, form, gems, instruct, itemNameText, listener, listings, newHTML, showOnly, treasure, treasureIndicator, updateListings,
  slice = [].slice;

TREASURE = 0;

GEMS = 1;

TD_ATTR = 'style="font-size:12px;"';

BBB_GUIDE = "<table>\n    <tr>\n        <th " + TD_ATTR + "><b>Muck (Familiars)</b></th>\n        <th " + TD_ATTR + "><b>Slime (Apparel)</b></th>\n        <th " + TD_ATTR + "><b>Misc</b></th>\n    </tr>\n    <tr>\n        <td " + TD_ATTR + ">Copper 50%</td>\n        <td " + TD_ATTR + ">Grey 70%(?)</td>\n        <td " + TD_ATTR + ">Green 45%</td>\n    </tr>\n    <tr>\n        <td " + TD_ATTR + ">Silver 30%</td>\n        <td " + TD_ATTR + ">White 20%(?)</td>\n        <td " + TD_ATTR + ">Yellow 20%</td>\n    </tr>\n    <tr>\n        <td " + TD_ATTR + ">Gold 20%</td>\n        <td " + TD_ATTR + ">Black 10%(?)</td>\n        <td " + TD_ATTR + ">Orange 15%</td>\n    </tr>\n    <tr> <td/> <td/> <td " + TD_ATTR + ">Red 10%</td> </tr>\n    <tr> <td/> <td/> <td " + TD_ATTR + ">Purple 8%</td> </tr>\n    <tr> <td/> <td/> <td " + TD_ATTR + ">Blue 2%</td> </tr>\n</table>\n<b>\n    <br>\n    Misc:<br>\n    Ooze (Material), Sludge (Trinkets), Goo (Food)\n</b>";

AH_BUTTON_SPACING = '140px';

AH_UPDATE_DELAY = 2000;

AH_DEFAULT_CURRENCY = void 0;

HILO_CLICK_MIN = 300;

HILO_CLICK_MAX = 1000;

BBB_BLINK_TIMEOUT = 250;

findMatches('a.navbar[href=\'main.php?p=pm\'],\na.navbar[href*=\'msgs\'],\na.navbar[href=\'main.php?p=ge\'],\na.navbar[href*=\'buy-gems\']', 2, 2).remove();

findMatches("a.navbar[href*=crossroads]").after('<a class=\'navbar navbar-glow-hover\' href=\'http://www1.flightrising.com/trading/baldwin/transmute\'>\n    Alchemy (Transmute)\n</a>\n<a class=\'navbar navbar-glow-hover\' href=\'http://www1.flightrising.com/trading/baldwin/create\'>\n    Alchemy (Create)\n</a>');

if (/www1/.test(window.location.href)) {
  treasureIndicator = findMatches('a.loginbar.loginlinks[title*=treasure]', 1, 1);
  currentTreasure = numberWithCommas(safeParseInt(treasureIndicator.text()));
  newHTML = treasureIndicator.html().replace(/\d+/, currentTreasure);
  treasureIndicator.html(newHTML);
} else {
  treasureIndicator = findMatches('span#user_treasure', 1, 1);
  currentTreasure = numberWithCommas(safeParseInt(treasureIndicator.text()));
  treasureIndicator.text(currentTreasure);
}

if ((new RegExp('http://www1\.flightrising\.com/trading/baldwin.*', 'i')).test(window.location.href)) {
  if (findMatches("input[value='Collect!']", 0, 1).length) {
    blinker = setInterval((function() {
      if (document.title === 'Ready!') {
        return document.title = '!!!!!!!!!!!!!!!!';
      } else {
        return document.title = 'Ready!';
      }
    }), BBB_BLINK_TIMEOUT);
    window.onfocus = function() {
      clearInterval(blinker);
      return document.title = 'Done.';
    };
  }
  if ((new RegExp('/baldwin/create')).test(window.location.href)) {
    bubble = findMatches('.baldwin-create-speech-bubble', 1, 1);
    instruct = findMatches('.baldwin-create-instruct', 1, 1);
    bubble.css('padding', '5px').css('right', 'inherit');
    instruct.css('background', 'inherit');
    bubble.html(BBB_GUIDE);
  }
} else if ((new RegExp("http://flightrising\.com/main\.php.*p=hilo", 'i')).test(window.location.href)) {
  setTimeout((function() {
    var playAgain;
    playAgain = findMatches('.mb_button[value="Play Again"]', 0, 1);
    if (playAgain.length) {
      return playAgain.click();
    }
  }), randInt(HILO_CLICK_MIN, HILO_CLICK_MAX));
} else if ((new RegExp('http://flightrising\.com/main\.php.*p=ah.*', 'i')).test(window.location.href)) {
  itemNameText = $('#searching > div:nth-child(1)');
  itemNameText.html(itemNameText.html() + '<a href=\'javascript:$("input[name=name").val("")\'>\n    &nbsp;(clear)\n</a>');
  AuctionListing = (function() {
    function AuctionListing(element) {
      this.element = element;
      this.numberOfItems = safeParseInt(this.element.find('div:nth-child(1) > span:nth-child(1) > span').text());
      this.button = this.element.find('[id*=buy_button]');
      this.price = safeParseInt(this.button.text());
      this.priceEA = this.price / this.numberOfItems;
      this.nameElement = this.element.find('div:nth-child(1) > span:nth-child(2) > span:nth-child(1)');
      this.name = this.nameElement.text();
    }

    AuctionListing.prototype.modifyElement = function() {
      var priceEAString, priceString, target;
      if (this.numberOfItems > 1) {
        target = this.button[0].childNodes[2];
        if (target == null) {
          return;
        }
        if (!safeParseInt(target.textContent) === this.price) {
          throw new Error("Tried to modify an auction house item but the price didn't match expectations.");
        }
        priceString = numberWithCommas(this.price);
        priceEAString = numberWithCommas(Math.round(this.priceEA));
        target.textContent = " " + priceString + " (" + priceEAString + " ea)";
      }
      this.button.css('width', AH_BUTTON_SPACING);
      return this.nameElement.html("<a href='javascript:$(\"input[name=name]\").val(\"" + this.name + "\")'>" + this.name + "</a>");
    };

    return AuctionListing;

  })();
  FormData = (function() {
    function FormData(form1) {
      this.form = form1;
    }

    FormData.prototype.field = function(name, newValue) {
      var field;
      field = this.form.find("[name=" + name + "]");
      if (newValue) {
        return field.val(newValue);
      } else {
        return field.val();
      }
    };

    return FormData;

  })();
  listings = void 0;
  updateListings = window.updateListings = function() {
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
  };
  form = new FormData(findMatches('form#searching', 1, 1));
  browseAllBackup = window.browseAll = function() {
    var args, cat, filledFields, gh, ghl, gl, gll, i, j, k, len, m, name, postData, ref, ref1, ref2, tab, th, thl, tl, tll;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    console.log.apply(console, ['browseAll called with'].concat(slice.call(args)));
    postData = {};
    postData.tab = args[0], postData.page = args[1], j = args.length - 2, postData.ordering = args[j++], postData.direct = args[j++];
    if (postData.page == null) {
      m = findMatches('#ah_left > div:nth-child(3) > span', 0, 1);
      if (m.length) {
        postData.page = m.text();
      } else {
        console.log('No page element found, assuming only 1 page.');
        postData.page = '1';
      }
    }
    if (postData.tab == null) {
      if ((tab = /[?&]tab=([^&]+)/.exec(window.location.href)) != null) {
        postData.tab = tab[1];
      } else {
        postData.tab = 'food';
      }
      if ((ref = !postData.tab) === 'food' || ref === 'mats' || ref === 'app' || ref === 'dragons' || ref === 'fam' || ref === 'battle' || ref === 'skins' || ref === 'other') {
        throw new Error("Detected tab as invalid option " + (postData.tab.toString()) + ".");
      }
    }
    if (postData.ordering == null) {
      if ($('img[src*="button_expiration_active.png"]').length) {
        postData.ordering = 'expiration';
      } else if ($('img[src*="button_price_active.png"]').length) {
        postData.ordering = 'cost';
      } else {
        throw new Error("Couldn't detect ordering (expiration or price).");
      }
    }
    if (postData.direct == null) {
      if ($('img[src*="button_ascending_active.png"]').length) {
        postData.direct = 'ASC';
      } else if ($('img[src*="button_descending_active.png"]').length) {
        postData.direct = 'DESC';
      } else {
        throw new Error("Couldn't detect sorting direction.");
      }
    }
    if ((cat = form.field('cat')).length) {
      postData.cat = cat;
    } else if ((name = form.field('name')).length) {
      postData.name = name;
    }
    tl = form.field('tl');
    th = form.field('th');
    gl = form.field('gl');
    gh = form.field('gh');
    ref1 = [tl.length, th.length, gl.length, gh.length], tll = ref1[0], thl = ref1[1], gll = ref1[2], ghl = ref1[3];
    filledFields = 0;
    ref2 = [tll, thl, gll, ghl];
    for (k = 0, len = ref2.length; k < len; k++) {
      i = ref2[k];
      if (i) {
        filledFields += 1;
      }
    }
    if (tll || thl) {
      if (tll) {
        postData.tl = tl;
      }
      if (thl) {
        postData.th = th;
      }
    } else if (gll || ghl) {
      if (gll) {
        postData.gl = gl;
      }
      if (ghl) {
        postData.gh = gh;
      }
    }
    console.log('Posting', postData);
    return $.ajax({
      type: "POST",
      data: postData,
      url: "includes/ah_buy_" + postData.tab + ".php",
      cache: false
    }).done(function(stuff) {
      findMatches("#ah_left", 1, 1).html(stuff);
      return setTimeout((function() {
        window.browseAll = browseAllBackup;
        return updateListings();
      }), 20);
    });
  };
  button = findMatches('input#go', 1, 1);
  button.attr('type', 'button');
  button.click(function() {
    return browseAllBackup();
  });
  setTimeout((function() {
    return browseAllBackup();
  }), 200);
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
  showOnly = function(currency) {
    var ref, ref1, them, us;
    if (currency === TREASURE) {
      ref = [treasure, gems], us = ref[0], them = ref[1];
    } else if (currency === GEMS) {
      ref1 = [gems, treasure], us = ref1[0], them = ref1[1];
    } else {
      throw new Error("showOnly called with invalid currency: " + currency);
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
  listener = function(event) {
    if (event.currentTarget === treasure.img[0]) {
      return showOnly(TREASURE);
    } else if (event.currentTarget === gems.img[0]) {
      return showOnly(GEMS);
    } else {
      throw new Error('Something in the auction house code has gone horribly wrong.');
    }
  };
  if (AH_DEFAULT_CURRENCY != null) {
    showOnly(AH_DEFAULT_CURRENCY);
    findMatches('input[type=submit]', 1, 1).click();
  }
  treasure.img.click(listener);
  gems.img.click(listener);
  treasure.img.css('cursor', 'pointer');
  gems.img.css('cursor', 'pointer');
}
