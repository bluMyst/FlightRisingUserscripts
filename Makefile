CFLAGS=-bc
CC=coffee

OSNAME:=$(shell uname -o)

ifeq ($(OS),Windows_NT)
    ifeq ($(OSNAME),Cygwin)
        CAT=cat
    else
        CAT=type
    endif
else
    CAT=cat
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
