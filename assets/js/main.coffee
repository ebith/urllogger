jQuery ->
  search = new Vue
    el: '#content'
    data:
      query: ''
      items: []
    created: ->
      do @recent
    methods:
      search: ->
        $.ajax
          url: '/search'
          dataType: 'json'
          data: q: @$data.query
          success: (json) =>
            @$data.items = (hit._source for hit in json.hits)
      recent: ->
        $.ajax
          url: '/recent'
          dataType: 'json'
          success: (json) =>
            @$data.items = (hit._source for hit in json.hits)
