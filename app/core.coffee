# Get the session user.
{Settings} = GitHub

{nickname} = KD.whoami().profile

class GitHub.Core.Utils
  @notify = (message)->
    new KDNotificationView
      title: message

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
  
  constructor:->
    @kite   = KD.getSingleton "kiteController"

  request:(url, callback, params)->
    @kite.run "curl -kL #{@API_ROOT}#{url}", (error, data)->
      
      # if any error exists or data is empty, try JSONP
      if error or not data
        return $.ajax 
          url         : "#{@API_ROOT}#{url}"
          data        : params
          dataType    : "jsonp"
          success     : callback
      
      # parse the curl result.
      try data = JSON.parse data
      callback {data}

  # That method should be more generic.
  getRepos:(@username, callback, @page = 1)->
    @repos or= []
    @request "/users/#{username}/repos", (response)=>
      {@meta, data} = response
      
      @repos.push repo for repo in data
      
      link = @meta?.Link?[0]
      if link?[1]?.rel is "next"
        @getRepos @username, callback, @page+1
      else 
        callback? data?.message, @repos
        @repos = []
    , 
      page: @page
      per_page: 20
      
  readRepoManifest: (appRepoName, callback)->
    manifestFile: "https://raw.github.com/#{@username}/#{appRepoName}/master/.manifest"
    @kite.run "curl -kL #{manifestFile}", (error, data)->
      try data = JSON.parse data
      callback error, data
      
class GitHub.Core.CLI

  @getSingleton: => @instance ?= new @

  constructor: ()->
    @kite   = KD.getSingleton "kiteController"
    @finder = KD.getSingleton "finderController"
    @tree   = @finder.treeController

  clone: (url, name, callback)->
    root = "/Users/#{nickname}/GitHub"
    path = "#{root}/#{name}"
    
    @kite.run "mkdir -p #{path}; git clone #{url} #{path}", =>
      KD.utils.wait 200, => 
        @tree.refreshFolder @tree.nodes[root]
      do callback

  cloneAsApp: (url, name, callback)->
    # Clear the repo name.
    name = name.replace(/.kdapp$/, '')
    root = "/Users/#{nickname}/Applications"
    path = "#{root}/#{name}.kdapp"
    
    @kite.run "mkdir -p #{path}; git clone #{url} #{path}", =>
      KD.utils.wait 200, => 
        @tree.refreshFolder @tree.nodes[root]
      do callback
