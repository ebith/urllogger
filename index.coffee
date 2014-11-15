request = require 'request'
liburl = require 'url'

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
      size: 20
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
      options =
        url: "http://localhost:#{Number(process.env.PORT) + 1 or 3001}/"
        json: true
        headers:
          url: appReq.body.url
      request.post options, (err, res, page) ->
        if not page.title or not page.body then return do appRes.status(406).end
        options =
          url: 'http://localhost:9200/url-logger/log'
          json:
            timestamp: new Date()
            url: appReq.body.url
            title: page.title
            body: page.body
            tags: {}
            icon: page.icon
            description: page.description
        options.json.tags[appReq.body.tag] = 1
        request.post options, (err, res, body) ->
          appRes.status(res.statusCode).json page
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
