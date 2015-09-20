// Generated by CoffeeScript 1.9.3

/* UserScript options {{{1
// ==UserScript==
// @name         FlightRising GUI Improvements
// @description  Improves the interface for Flight Rising.
// @namespace    ahto
// @version      1.22.5
// @include      http://*flightrising.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=61626
// @grant        none
// ==/UserScript==
 */

/* Features and changes {{{1
General:
- Adds two new links to Baldwin's Bubbling Brew.
- Removes redundant links to messages and gems.
- Adds commas to various numbers around the site.
- Automatically bonds with familiars.

Auction House:
- Clicking the icons next to price ranges will let you sort by only treasure or only gems.
- Tells you how much items cost per unit.
- Adds a clear item name button.
- Clicking an item's name sets that to the name filter.

Baldwin's Bubbling Brew:
- Replaces useless dialog text with a handy guide.
- Flashes title when your brew is ready. (Leave BBB running in a background tab)

Higher or Lower game:
- Automatically clicks 'play again'.
- Added keyboard shortcuts for each of the guesses.

Mail:
- Auto-collects attachments.
- Selecting a message for deletion highlights the whole thing.
 */
var AH_BUTTON_SPACING, AH_DEFAULT_CURRENCY, AH_UPDATE_DELAY, AuctionListing, BBB_BLINK_TIMEOUT, BBB_GUIDE, CurrencyFields, CurrencyFilterer, FormData, GEMS, HUMAN_TIMEOUT_MAX, HUMAN_TIMEOUT_MIN, LOADING_WAIT, TD_ATTR, TREASURE, blinker, bondButton, brew, browseAllBackup, bubble, button, buttonHi, buttonLo, buttonTitle, currentTreasure, exit, filterer, form, getTab, guesses, injectScript, instruct, itemNameText, j, len, newHTML, playAgain, price, ref, sell, setHumanTimeout, treasureIndicator, updateButton, updateListings, urlMatches,
  slice = [].slice;

TREASURE = 0;

GEMS = 1;

TD_ATTR = 'style="font-size:12px;"';

BBB_GUIDE = "<table>\n    <tr>\n        <th " + TD_ATTR + "><b>Muck (Familiars)</b></th>\n        <th " + TD_ATTR + "><b>Slime (Apparel)</b></th>\n        <th " + TD_ATTR + "><b>Misc</b></th>\n    </tr>\n    <tr>\n        <td " + TD_ATTR + ">Copper 50%</td>\n        <td " + TD_ATTR + ">Grey 70%(?)</td>\n        <td " + TD_ATTR + ">Green 45%</td>\n    </tr>\n    <tr>\n        <td " + TD_ATTR + ">Silver 30%</td>\n        <td " + TD_ATTR + ">White 20%(?)</td>\n        <td " + TD_ATTR + ">Yellow 20%</td>\n    </tr>\n    <tr>\n        <td " + TD_ATTR + ">Gold 20%</td>\n        <td " + TD_ATTR + ">Black 10%(?)</td>\n        <td " + TD_ATTR + ">Orange 15%</td>\n    </tr>\n    <tr> <td/> <td/> <td " + TD_ATTR + ">Red 10%</td> </tr>\n    <tr> <td/> <td/> <td " + TD_ATTR + ">Purple 8%</td> </tr>\n    <tr> <td/> <td/> <td " + TD_ATTR + ">Blue 2%</td> </tr>\n</table>\n<b>\n    <br>\n    Misc:<br>\n    Ooze (Material), Sludge (Trinkets), Goo (Food)\n</b>";

AH_BUTTON_SPACING = '140px';

AH_UPDATE_DELAY = 2000;

AH_DEFAULT_CURRENCY = void 0;

HUMAN_TIMEOUT_MIN = 300;

HUMAN_TIMEOUT_MAX = 1000;

BBB_BLINK_TIMEOUT = 500;

LOADING_WAIT = 1000;

exit = function() {
  throw new Error('Not an error just exiting early');
};

setHumanTimeout = function(f, extraTime) {
  if (extraTime == null) {
    extraTime = 0;
  }
  return setTimeout(f, randInt(HUMAN_TIMEOUT_MIN + extraTime, HUMAN_TIMEOUT_MAX + extraTime));
};

injectScript = function(f) {
  var script, source;
  if (typeof f === 'function') {
    source = "(" + f + ")();";
  }
  script = $("<script type='application/javascript'>\n    " + source + "\n</script>");
  $(document).append(script);
  return script.remove();
};

urlMatches = function(regexp) {
  return regexp.test(window.location.href);
};

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

if (urlMatches(new RegExp('http://www1\.flightrising\.com/trading/baldwin.*', 'i'))) {
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
      return document.title = 'Ready!';
    };
  }
  if ((new RegExp('/baldwin/create')).test(window.location.href)) {
    bubble = findMatches('.baldwin-create-speech-bubble', 1, 1);
    instruct = findMatches('.baldwin-create-instruct', 1, 1);
    bubble.css('padding', '5px').css('right', 'inherit');
    instruct.css('background', 'inherit');
    bubble.html(BBB_GUIDE);
  }
  brew = window.brew = function(id, n) {
    if (n == null) {
      n = 1;
    }
    if (n <= 0) {
      return;
    }
    $('#baldwin-transmute-btn').click();
    return setTimeout((function() {
      var itemInList;
      itemInList = $("a[rel='#tooltip-" + id + "']");
      itemInList = $(itemInList[itemInList.length - 1]);
      itemInList.click();
      return setTimeout((function() {
        $('#attch').click();
        return setTimeout((function() {
          $('#transmute-confirm-ok').click();
          return setTimeout((function() {
            return brew(id, n - 1);
          }), LOADING_WAIT);
        }), LOADING_WAIT);
      }), LOADING_WAIT);
    }), LOADING_WAIT);
  };
}

if (urlMatches(new RegExp('http://flightrising\.com/main\.php.*p=market', 'i'))) {
  ref = findMatches('#market > div > div:nth-child(3) > div:nth-child(4)', 1);
  for (j = 0, len = ref.length; j < len; j++) {
    price = ref[j];
    price = $(price);
    price.text(numberWithCommas(safeParseInt(price.text())));
  }
}

if (urlMatches(new RegExp("http://flightrising\.com/main\.php.*p=hilo", 'i'))) {
  guesses = parseInt(findMatches('#super-container > div:nth-child(2) > div:nth-child(4) > div:nth-child(2)', 1, 1).text());
  if (guesses > 0) {
    playAgain = findMatches('.mb_button[value="Play Again"]', 0, 1);
    if (playAgain.length) {
      setHumanTimeout(function() {
        return playAgain.click();
      });
    } else {
      findMatches('#super-container > div:nth-child(3) > div:nth-child(3)', 1, 1).html('Press <b>j (lower)</b> or <b>k (higher)</b>, or use the buttons on the left.<br>\nIf you guess correctly, you\'ll win 65 treasure (as of 2015.09.10).');
      buttonLo = findMatches('map[name=hilo_map] > area[href*="choice=lo"]', 1, 1);
      buttonHi = findMatches('map[name=hilo_map] > area[href*="choice=hi"]', 1, 1);
      $(document).keypress(function(e) {
        switch (String.fromCharCode(e.charCode).toLowerCase()) {
          case 'j':
            return buttonLo.click();
          case 'k':
            return buttonHi.click();
          default:
            return console.log("Got unrechognized charCode: " + e.charCode);
        }
      });
    }
  }
}

if (urlMatches(new RegExp("http://flightrising\.com/main\.php.*p=lair", 'i'))) {
  if ((bondButton = findMatches('img[src*="button_bond.png"]', 0, 1)).length) {
    setHumanTimeout(function() {
      bondButton.click();
      return setHumanTimeout(function() {
        return findMatches('button#no', 1, 1).click();
      });
    });
  } else if (findMatches('img[src*="button_bond_inactive.png"]', 0, 1).length) {
    document.title = 'Bonded!';
  }
}

if (urlMatches(new RegExp('http://flightrising\.com/main\.php.*p=ah', 'i'))) {
  if (findMatches('input[value=Search]', 0, 1).length) {
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
        target = this.button[0].childNodes[2];
        if (target == null) {
          console.warn("Tried to modifyElement() for " + this.name + " @ " + this.price + " but the auction expired(?).");
          return;
        }
        if (!safeParseInt(target.textContent) === this.price) {
          throw new Error("Tried to modify an auction house item but the price didn't match expectations.");
        }
        priceString = numberWithCommas(this.price);
        priceEAString = numberWithCommas(Math.round(this.priceEA));
        if (this.numberOfItems > 1) {
          target.textContent = " " + priceString + " (" + priceEAString + " ea)";
        } else {
          target.textContent = " " + priceString;
        }
        this.button.css('width', AH_BUTTON_SPACING);
        return this.nameElement.html("<a href='javascript:$(\"input[name=name]\").val(\"" + this.name + "\")'>" + this.name + "</a>");
      };

      return AuctionListing;

    })();
    getTab = function() {
      var ref1, tab;
      if ((tab = /[?&]tab=([^&]+)/.exec(window.location.href)) != null) {
        tab = tab[1];
      } else {
        tab = 'food';
      }
      if ((ref1 = !tab) === 'food' || ref1 === 'mats' || ref1 === 'app' || ref1 === 'dragons' || ref1 === 'fam' || ref1 === 'battle' || ref1 === 'skins' || ref1 === 'other') {
        throw new Error("Detected tab as invalid option " + (postData.tab.toString()) + ".");
      }
      return tab;
    };
    CurrencyFields = (function() {
      function CurrencyFields(img, low, high) {
        this.img = img;
        this.low = low;
        this.high = high;
      }

      CurrencyFields.prototype.notEmpty = function() {
        var val;
        val = this.low.val().length || this.high.val().length;
        return val;
      };

      return CurrencyFields;

    })();
    CurrencyFilterer = (function() {
      CurrencyFilterer.prototype.LOW = '0';

      CurrencyFilterer.prototype.HIGH = '999999999999999999';

      function CurrencyFilterer(searchButton, treasureFields, gemFields) {
        this.searchButton = searchButton;
        this.treasureFields = treasureFields;
        this.gemFields = gemFields;
        this.treasureListener = this.makeListener(this.treasureFields, this.gemFields);
        this.gemListener = this.makeListener(this.gemFields, this.treasureFields);
      }

      CurrencyFilterer.prototype.makeListener = function(us, them) {
        return (function(_this) {
          return function(event) {
            if (us.notEmpty()) {
              us.low.val('');
              us.high.val('');
            } else {
              us.low.val(_this.LOW);
              us.high.val(_this.HIGH);
            }
            them.low.val('');
            return them.high.val('');
          };
        })(this);
      };

      CurrencyFilterer.prototype.init = function() {
        this.treasureFields.img.click(this.treasureListener);
        this.gemFields.img.click(this.gemListener);
        this.treasureFields.img.css('cursor', 'pointer');
        this.gemFields.img.css('cursor', 'pointer');
        if (AH_DEFAULT_CURRENCY != null) {
          return filterer.showOnly(AH_DEFAULT_CURRENCY);
        }
      };

      CurrencyFilterer.prototype.showOnly = function(currency) {
        switch (currency) {
          case TREASURE:
            this.treasureListener();
            break;
          case GEMS:
            this.gemListener();
            break;
          default:
            throw new Error("CurrencyFilterer.showOnly called with invalid currency: " + currency);
        }
        return this.searchButton.click();
      };

      return CurrencyFilterer;

    })();
    filterer = new CurrencyFilterer(findMatches('input[value=Search]', 1, 1).click(), new CurrencyFields(findMatches('#searching img[src="/images/layout/icon_treasure.png"]', 1, 1), findMatches('input[name=tl]', 1, 1), findMatches('input[name=th]', 1, 1)), new CurrencyFields(findMatches('#searching img[src="/images/layout/icon_gems.png"]', 1, 1), findMatches('input[name=gl]', 1, 1), findMatches('input[name=gh]', 1, 1)));
    filterer.init();
    if (getTab() !== 'dragons') {
      itemNameText = $('#searching > div:nth-child(1)');
      itemNameText.html(itemNameText.html() + '<a href=\'javascript:$("input[name=name").val("")\'>\n    &nbsp;(clear)\n</a>');
      updateListings = function() {
        var i, k, len1, listings, results;
        listings = (function() {
          var k, len1, ref1, results;
          ref1 = $('#ah_left div[id*=sale]');
          results = [];
          for (k = 0, len1 = ref1.length; k < len1; k++) {
            i = ref1[k];
            results.push(new AuctionListing($(i)));
          }
          return results;
        })();
        results = [];
        for (k = 0, len1 = listings.length; k < len1; k++) {
          i = listings[k];
          results.push(i.modifyElement());
        }
        return results;
      };
      updateListings();
      form = new FormData(findMatches('form#searching', 1, 1));
      browseAllBackup = window.browseAll = function() {
        var args, cat, filledFields, gh, ghl, gl, gll, i, k, l, len1, name, postData, ref1, th, thl, tl, tll;
        args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        console.log('browseAll called with', args);
        postData = {};
        postData.tab = args[0], postData.page = args[1], k = args.length - 2, postData.ordering = args[k++], postData.direct = args[k++];
        if (postData.page == null) {
          postData.page = 1;

          /*
          m = findMatches('#ah_left > div:nth-child(3) > span', 0, 1)
          
          if m.length
              postData.page = m.text()
          else
              console.log 'No page element found, assuming only 1 page.'
              postData.page = '1'
           */
        }
        if (postData.tab == null) {
          postData.tab = getTab();
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
        if ((cat = form.field('cat'))) {
          postData.cat = cat;
        }
        if ((name = form.field('name'))) {
          postData.name = name;
        }
        tl = form.field('tl');
        th = form.field('th');
        gl = form.field('gl');
        gh = form.field('gh');
        tll = tl ? tl.length : 0;
        thl = th ? th.length : 0;
        gll = gl ? gl.length : 0;
        ghl = gh ? gh.length : 0;
        filledFields = 0;
        ref1 = [tll, thl, gll, ghl];
        for (l = 0, len1 = ref1.length; l < len1; l++) {
          i = ref1[l];
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
          }), 100);
        });
      };
      button = findMatches('input#go', 1, 1);
      button.attr('type', 'button');
      button.click(function() {
        return browseAllBackup();
      });
      setTimeout((function() {
        return browseAllBackup();
      }), 400);
      findMatches('form#searching input[type=text]').keydown(function(e) {
        if (e.keyCode === 13) {
          return button.click();
        }
      });
      buttonTitle = 'Tells the userscript to update formatting (show price ea and other information)\non this page, since the code for doing that automatically has a tendency to\nforget.';
      updateButton = $("<input type=button value=\"Update formatting\" title=\"" + buttonTitle + "\" class=mb_button>");
      updateButton.click(function() {
        window.browseAll = window.browseAllBackup = browseAllBackup;
        return updateListings();
      });
      findMatches('#go', 1, 1).after(updateButton);
    }
  }
}

if (urlMatches(new RegExp('flightrising\.com/main\.php.*action=sell', 'i'))) {
  sell = window.sell = function(id, nListings, price, quantity) {
    var itemInList;
    if (quantity == null) {
      quantity = 1;
    }
    if (nListings <= 0) {
      return;
    }
    itemInList = $("a[rel][onclick*='\\'" + id + "\\'']");
    itemInList = $(itemInList[itemInList.length - 1]);
    itemInList.click();
    return setTimeout((function() {
      var durationDropdown, gemRadio, postAuctionButton, quantityDropdown, treasurePrice, treasureRadio;
      quantityDropdown = $('select[name=qty]');
      durationDropdown = $('select[name=drtn]');
      treasurePrice = $('input[name=treas]');
      treasureRadio = $('input[type=radio][name=cur][value=t]');
      gemRadio = $('input[type=radio][name=cur][value=g]');
      postAuctionButton = $('input[type=submit][value="Post Auction"]');
      treasureRadio.click();
      treasurePrice.val(price.toString());
      quantityDropdown.val(quantity);
      durationDropdown.val(3);
      return setHumanTimeout((function() {
        postAuctionButton.click();
        return setHumanTimeout((function() {
          $('button#yes').click();
          return setHumanTimeout((function() {
            $('button#yes').click();
            return setHumanTimeout((function() {
              return sell(id, nListings - 1, price, quantity);
            }), LOADING_WAIT);
          }), LOADING_WAIT);
        }), LOADING_WAIT);
      }), LOADING_WAIT);
    }), LOADING_WAIT);
  };
}

if (urlMatches(new RegExp('http://www1\.flightrising\.com/msgs/[0-9]+', 'i'))) {
  setHumanTimeout(function() {
    findMatches('button#take-items', 1, 1).click();
    return setHumanTimeout(function() {
      findMatches('button#confirm', 1, 1).click();
      return document.title = 'Collected!';
    });
  });
}
