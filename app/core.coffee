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
    @store.fetchValue key, callback


# GitHub Connector to connect and get data from GitHub API.
class GitHub.Core.Connector
    
  API_ROOT    : "https://api.github.com"
  
  constructor:->
    @kite   = KD.getSingleton "kiteController"

  request:(url, callback, params)->
    @kite.run "curl -kLss #{@API_ROOT}#{url}", (error, data)->
      
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

  readAppRepoOldManifest: (appRepoName, callback)->
    manifestFile = "https://raw.github.com/#{@username}/#{appRepoName}/master/.manifest"
    @kite.run "curl -kLss #{manifestFile}", (error, data)->
      try data = JSON.parse data
      callback error, data

  readAppRepoManifest: (appRepoName, callback)->
    manifestFile = "https://raw.github.com/#{@username}/#{appRepoName}/master/manifest.json"
    @kite.run "curl -kLss #{manifestFile}", (error, data)->
      try data = JSON.parse data
      callback error, data
      
  getAppRepoIconFullURL: (appRepoName, callback)->
    appBase = "https://raw.github.com/#{@username}/#{appRepoName}/master/"
    @readAppRepoManifest appRepoName, (error, manifest)=>
      if typeof manifest is "string" then error = yes
      if error or not manifest
        @readAppRepoOldManifest appRepoName, (error, manifest)->
          iconPath = manifest?.icns?["128"]
          callback "#{appBase}#{iconPath}", manifest
        return false
      
      iconPath = manifest?.icns?["128"]
      callback "#{appBase}#{iconPath}", manifest


class GitHub.Core.CLI

  @getSingleton: => @instance ?= new @

  constructor: ()->
    @kite   = KD.getSingleton "kiteController"
    @finder = KD.getSingleton "finderController"
    @vm     = KD.getSingleton "vmController"

  clone: (url, name, callback)->
    root = "/home/#{nickname}/GitHub"
    path = "#{root}/#{name}"
    
    @kite.run "mkdir -p #{path}; git clone #{url} #{path}", =>
      callback.apply @, arguments

  cloneAsApp: (url, name, callback)->
    # Clear the repo name.
    name = name.replace(/.kdapp$/, '')
    root = "/home/#{nickname}/Applications"
    path = "#{root}/#{name}.kdapp"
    
    @kite.run "mkdir -p #{path}; git clone #{url} #{path}; mv #{path}/.manifest #{path}/manifest.json", =>
      KD.getSingleton('kodingAppsController').refreshApps()
      callback.apply @, arguments
