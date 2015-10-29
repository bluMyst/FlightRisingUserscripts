# vim: foldmethod=marker
# imports {{{1
#!/usr/bin/python

import requests
# http://requests.readthedocs.org/en/latest/user/quickstart/
import re
import urlparse
from pprint import pprint

# example cookie: {{{1
# "PHPSESSID=1icshb8cham70qt3bqgat9ipb3; userid=170898; user_key=9cabc1a01f1879f7c8f5cefcf9f27764b1236f3e; username=bluMyst; _gat_ls=1; _gat=1; _ga=GA1.2.1008608779.1434945534"

BASE_HEADERS = { # {{{1
    'Accept':           '*/*',
    'Accept-Encoding':  'gzip, deflate',
    'Accept-Language':  'en-US,en;q=0.8',
    'Connection':       'keep-alive',

    # The MIME type of the body of the request (used with POST and PUT requests)
    # TODO: Is requests smart enough to set this by itself?
    # TODO: This could also be multipart/form-data or text/plain, but when
    # should we set it, and to what?
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',

    # Do Not Track
    'DNT': '1',

    'User-Agent':        'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36',
}

# functions {{{1
def stealth_headers(from_js, is_post, ref, url, etc): # {{{2
    ''' Modify BASE_HEADERS to be extra stealthy and custom-built.

    from_js:  Are we emulating an Ajax request (true) or a normal POST/GET request (false)?
    is_post:  Is it a POST (true) or a GET (false)?
    ref:      The referrer.
    url:      The target URL.
    etc:      A dict of other headers to set.
    '''
    r = BASE_HEADERS.copy()

    # This is the address of the previous web page from which a link to the
    # currently requested page was followed.
    r['Referer'] = ref
    ref_parsed = urlparse.urlparse(ref)

    if from_js:
        # mainly used to identify Ajax requests. Most JavaScript frameworks
        # send this field with value of XMLHttpRequest
        r['X-Requested-With'] = 'XMLHttpRequest'

    # The domain name of the server (for virtual hosting).
    # TODO: Does requests set this automatically?
    #'Host': 'flightrising.com',
    r['Host'] = ref_parsed.netloc

    if is_post:
        # Chrome and Safari include an Origin header on same-origin POST/PUT/DELETE
        # requests (same-origin GET requests will not have an Origin header).
        # Firefox doesn't include an Origin header on same-origin requests.
        # http://stackoverflow.com/questions/15512331/chrome-adding-origin-header-to-same-origin-request
        #'Origin': 'http://flightrising.com',
        r['Origin'] = urlparse.urlunparse((ref_parsed.scheme, ref_parsed.netloc, '', '', '', ''))

    r.update(etc)

    return r

def no_whitespace(string): # {{{2
    return ''.join(string.split())

def cookie_parser(string): # {{{2
    # "key=value; key2=value2;"
    return dict(
        [i.split('=') for i in re.split(';\s*', string)]
    )

def yes_no(prompt, default=None): # {{{2
    if default == None:
        prompt += ' [yn]'
    elif default:
        prompt += ' [Yn]'
    else:
        prompt += ' [yN]'

    answer = raw_input(prompt)

    if answer.lower() in ['y', 'yes']:
        return True
    elif answer.lower() in ['n', 'no']:
        return False
    elif default != None:
        return default
    else:
        print 'Invalid answer: "{answer}"'.format(**locals())
        return yes_no(prompt, default)

if __name__ == '__main__': # {{{1
    while True:
        cookie = cookie_parser(raw_input('Paste cookie: '))

        pprint(cookie)
        if yes_no('Does that look right?', True):
            break

    # r = requests.post(url, cookies=cookie, headers=HEADERS)
