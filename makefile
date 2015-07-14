CFLAGS=-bc
CC=coffee

ifeq ($(OS),Windows_NT)
    ifeq ($(OSTYPE),cygwin)
        CAT=cat
    else
        CAT=type
    endif
endif

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
	$(CAT) ahtoLib.js sandbox.js | clip

%: %.js
	clip < $<
