TREASURE=0
GEMS=1

class FormData
    constructor: (@form) ->

    field: (name, newValue) ->
        # pass no newValue to get current value.
        field = @form.find "[name=#{name}]"

        if newValue
            return field.val(newValue)
        else
            return field.val()

form = new FormData findMatches('form#searching', 1, 1)

# TODO Get all info from environment, don't rely on arguments.
#      When done, uncomment button code below.
browseAllBackup = window.browseAll = (args...) ->
    console.log 'browseAll called with', args...
    # tl = treasure low  gh = gems high
    # Arguments are:
    # tab, page, [maybe cat], [lohi], [maybe name], ordering, direct
    # lohi = [treasure lohi] or [gem lohi] or [nothing]
    # X lohi = X hi or X lo or (X lo, X hi)
    postData = {}

    [
        postData.tab,
        postData.page,
        ...,
        postData.ordering,
        postData.direct,
    ] = args

    # TODO
    # Find the left arrow, and the page number is the only span sibling.
    # img gets wrapped with a when it's active; doesn't work
    postData.page = $('#ah_left > div > img[src*="/images/layout/arrow_left"] ~ span').text()

    if (cat = form.field 'cat').length
        postData.cat = cat
    else if (name = form.field 'name').length
        postData.name = name

    tl = form.field 'tl'
    th = form.field 'th'
    gl = form.field 'gl'
    gh = form.field 'gh'

    [tll, thl, gll, ghl] = [tl.length, th.length, gl.length, gh.length]
    filledFields = 0

    for i in [tll, thl, gll, ghl]
        if i then filledFields += 1

    # Defaults to treasure just like the original code does.
    if tll or thl
        if tll then postData.tl = tl
        if thl then postData.th = th
    else if gll or ghl
        if gll then postData.gl = gl
        if ghl then postData.gh = gh

    console.log 'Posting', postData
    $.ajax({
        type: "POST",
        data:  postData,
        url:   "includes/ah_buy_#{postData.tab}.php",
        cache: false,
    }).done((stuff) ->
        findMatches("#ah_left", 1, 1).html(stuff)

        # TODO This timeout is necessary but if you click too fast you can
        #      end up accidentally calling the original browseAll() instead.
        setTimeout((->
            window.browseAll = browseAllBackup
        ), 20)
    )

###
button = findMatches('input#go', 1, 1)
button.click(->
    browseAllBackup
)
###
