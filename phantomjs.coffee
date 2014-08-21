system = require('system')

require('webserver').create().listen system.env.PORT + 1 or 3001, (request, response) ->
  page = require('webpage').create()
  page.settings.loadImages = false

  finalized = false

  i = 0
  page.onResourceReceived = (res) ->
    if i is 0 and not /text\/html/.test(res.contentType)
      do page.close
      response.statusCode = 400
      response.write '{}'
      do response.close
      finalized = true
    i++

  page.open request.headers.url, (status) ->
    result = page.evaluate(->
      title: document.title
      body: document.body.textContent.replace(/\s+/g, ' ')
      description: document.getElementsByName('description')[0]?.content
      icon: (e.href for e in document.getElementsByTagName('link') when /^shortcut\s+icon$|^icon$/.test e.rel)[0] or "#{document.location.protocol}//#{document.location.host}/favicon.ico"
    )

    if not finalized
      do page.close
      response.statusCode = 200
      response.write JSON.stringify(result)
      do response.close
