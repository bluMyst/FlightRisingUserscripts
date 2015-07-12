// Generated by CoffeeScript 1.9.3
var findMatches, randInt, safeInterval, safeParseInt;

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

String.prototype.hashCode = function() {
  var chr, hash, i, j, len;
  hash = 0;
  for (j = 0, len = this.length; j < len; j++) {
    i = this[j];
    chr = i.charCodeAt(0);
    hash = ((hash << 5) - hash) + chr;
    hash |= 0;
  }
  return hash;
};

randInt = function(min, max) {
  return min + Math.floor(Math.random() * (max + 1 - min));
};
