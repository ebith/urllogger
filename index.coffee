request = require 'request'
liburl = require 'url'
nightmare = require 'nightmare'

express = require 'express'
bodyParser = require 'body-parser'
connectAssets = require 'connect-assets'
app = do express
app.set 'view engine', 'jade'
app.use do bodyParser.json
app.use do connectAssets
# app.use express.static "#{__dirname}/public"

app.get '/', (req, res) ->
  res.render 'index'
app.get '/recent', (appReq, appRes) -> # {{{
  options =
    url: 'http://localhost:9200/url-logger/log/_search'
    json:
      _source:
        exclude: ['body']
      size: 100
      sort:
        timestamp: order: 'desc'
      # filter:
      #   not:
      #     range:
      #       test:
      #         gt: 0
  request.get options, (err, res, body) ->
    appRes.json body.hits
# }}}
app.get '/search', (appReq, appRes) -> # {{{
  if not appReq.query.q then return do appRes.status(400).end
  options =
    url: 'http://localhost:9200/url-logger/log/_search'
    json:
      _source:
        exclude: ['body']
      query:
        simple_query_string:
          query: appReq.query.q
          fields: ['_all']
          default_operator: 'and'
  request.get options, (err, res, body) ->
    appRes.json body.hits
# }}}

app.post '/', (appReq, appRes) -> # {{{
  if not /http|https/.test liburl.parse(appReq.body.url).protocol then return do appRes.status(400).end
  options =
    url: 'http://localhost:9200/url-logger/log/_search'
    json:
      _source:
        exclude: ['body']
      filter:
        term:
          'url.full': appReq.body.url
  request.get options, (err, res, body) ->
    hits = body.hits
    if hits.total is 0 or new Date().getTime() > new Date(hits[0]._source.timestamp) + 2629743830 # 一ヶ月前
      new nightmare(loadImages: false)
        .useragent 'Mozilla/5.0'
        .goto appReq.body.url
        .evaluate ->
          title: document.title
          body: document.body.textContent.replace(/\s+/g, ' ')
          description: document.getElementsByName('description')[0]?.content
          icon: (e.href for e in document.getElementsByTagName('link') when /^shortcut\s+icon$|^icon$/.test e.rel)[0] or "#{document.location.protocol}//#{document.location.host}/favicon.ico"
        , (page) ->
          if not page.title or not page.body then return do appRes.status(406).end
          imgUrl2base64 page.icon, (icon) ->
            options =
              url: 'http://localhost:9200/url-logger/log'
              json:
                timestamp: new Date()
                url: appReq.body.url
                title: page.title
                body: page.body
                tags: {}
                icon: icon
                description: page.description
            options.json.tags[appReq.body.tag] = 1
            request.post options, (err, res, body) ->
              appRes.status(res.statusCode).json page
        .run()
    else
      options =
        url: "http://localhost:9200/url-logger/log/#{hits.hits[0]._id}/_update"
        json:
          doc:
            timestamp: new Date()
            tags: {}
      options.json.doc.tags[appReq.body.tag] = hits.hits[0]._source.tags[appReq.body.tag] + 1 || 1
      request.post options, (err, res, body) ->
        appRes.status(res.statusCode).json hits.hits[0]._source
# }}}

app.listen process.env.PORT or '3000'

imgUrl2base64 = (url, callback) ->
  request.get url, encoding: 'binary', (err, res, body) ->
    if res.statusCode is 200
      img = new Buffer(body.toString(), 'binary').toString 'base64'
      callback "data:#{res.headers['content-type']};base64,#{img}"
    else
      callback 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7' # 空白画像
