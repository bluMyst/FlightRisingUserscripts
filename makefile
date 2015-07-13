CFLAGS=-bc
CC=coffee

# don't remove intermediate files
.SECONDARY:

all: *.js

# $< is the first item in the dependencies list
# % lets us generalize for all .js files
%.js: %.coffee
	$(CC) $(CFLAGS) $<

%: %.js ahtoLib.js
	cat ahtoLib.js $< | clip
