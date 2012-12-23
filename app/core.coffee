# Base Hierarchy
# Defining all the namespaces here, to make the app more readable.

GitHub = 
    # Core classes
    Core:
        # Connector uses JSONP to connect and collect
        # required data.
        Connector   : null
        # CL Interface uses kites to repository
        # interactions.
        CLI         : null
    # Core Models
    Models:
        # Repo Model for collected repos
        Repo        : null
    # Core Views, the beauty part.
    Views:
        # Repo View, the front-end part of the Repo Model.
        RepoView    : null
        # Repos List View, controller of the RepoViews.
        ReposView   : null
        # MainView the main controller of the controllers.
        MainView    : null

# Get the session user.
{nickname} = KD.whoami().profile

class GitHub.Core.Connector
    
    API_ROOT    : "https://api.github.com"

    request:(url, callback, data)->
        $.ajax 
            url         : "#{@API_ROOT}#{url}"
            data        : data
            dataType    : "jsonp"
            success     : callback

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

    constructor: ()->
        @kite = KD.getSingleton "kiteController"

    clone: (url, name, callback)->
        path = "/Users/#{nickname}/GitHub/#{name}"
        @kite.run "mkdir -p #{path}; git clone #{url} #{path}", callback

    cloneAsApp: (url, name, callback)->
        path = "/Users/#{nickname}/Applications/#{name}.kdapp"
        @kite.run "mkdir -p #{path}; git clone #{url} #{path}", callback
        
    