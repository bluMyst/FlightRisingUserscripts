CFLAGS=-bc
CC=coffee

# don't remove intermediate files
.SECONDARY:

all: *.js

# $< is the first item in the dependencies list
# % lets us generalize for all .js files
%.js: %.coffee
	$(CC) $(CFLAGS) $<

# The sandbox is meant to be pasted right into a javascript console
# so ahtoLib is automatically included.
sandbox: sandbox.js
	cat ahtoLib.js sandbox.js | clip

%: %.js
	clip < $<
