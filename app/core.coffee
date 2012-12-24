# Get the session user.
{Settings} = GitHub

{nickname} = KD.whoami().profile

# layer of storage, so we can port another storage easily.
class GitHub.Core.Storage

  @getSingleton: => @instance ?= new @
  
  constructor: ->
    @store = new AppStorage Settings.appStorageName, "0.1"
  
  set: (key, value) ->
    @store.setValue key, value
  
  get: (key, callback) ->
    @store.getValue key, callback

# GitHub Connector to connect and get data from GitHub API.
class GitHub.Core.Connector
    
  API_ROOT    : "https://api.github.com"

  request:(url, callback, data)->
    $.ajax 
      url         : "#{@API_ROOT}#{url}"
      data        : data
      dataType    : "jsonp"
      success     : callback

  # That method should be more generic.
  getRepos:(@username, callback, @page = 1)->
    @repos or= []
    @request "/users/#{username}/repos", (response)=>
      {@meta, data} = response
      @repos.push repo for repo in data
      
      link = @meta.Link?[0]
      if link?[1]?.rel is "next"
        @getRepos @username, callback, @page+1
      else 
        callback? @repos
    , 
      page: @page
      per_page: 20
            
class GitHub.Core.CLI

  @getSingleton: => @instance ?= new @

  constructor: ()->
    @kite = KD.getSingleton "kiteController"

  clone: (url, name, callback)->
    path = "/Users/#{nickname}/GitHub/#{name}"
    @kite.run "mkdir -p #{path}; git clone #{url} #{path}", callback

  cloneAsApp: (url, name, callback)->
    # Clear the repo name.
    name = name.replace(/.kdapp$/, '')
    
    path = "/Users/#{nickname}/Applications/#{name}.kdapp"
    @kite.run "mkdir -p #{path}; git clone #{url} #{path}", callback
      
    
class GitHub.Core.Utils
  @notify = (message)->
    new KDNotificationView
      title: message