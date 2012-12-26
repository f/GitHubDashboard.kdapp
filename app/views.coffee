{Settings}                  = GitHub
{Connector, Storage, CLI}   = GitHub.Core
{Repo}                      = GitHub.Models

{notify}                    = GitHub.Core.Utils

class GitHub.Views.RepoView extends KDListItemView

  constructor: (options, @data)->
    options.cssClass = "repo-item"
    @model = new Repo @data
    
    super
    
  partial: ()->
    """
    #{@data.name} - 
    <a href="#" class="clone">Clone</a>
    """

  # Should be more elegant.
  click: (e)->
    
    if e.target.className is "clone"
    
      notify "Cloning the #{@data.name} repository..."
            
      @model.clone =>
        notify "#{@data.name} successfully cloned."


class GitHub.Views.AppRepoView extends KDListItemView

  constructor: (options, @data)->
    options.cssClass = "app-repo-item"
    @model = new Repo @data
    
    super
    
  partial: ()->
    """
    #{@data.name} - 
    <a href="#" class="install">Install</a>
    <a href="#" class="clone">Clone</a>
    """

  # Should be more elegant.
  click: (e)->
    
    if e.target.className is "install"
        
      notify "Cloning the #{@data.name} repository as Koding App..."
          
      @model.cloneAsApp =>
        notify "#{@data.name} successfully cloned."
        
    else if e.target.className is "clone"
    
      notify "Cloning the #{@data.name} repository..."
            
      @model.clone =>
        notify "#{@data.name} successfully cloned."




class GitHub.Views.ReposView extends KDListViewController

  # Empty repos
  repos: []

  resetRepos: (repos, data = {})->
    @repos = []
    @replaceAllItems []
    $.each repos, (i, repo)=>
      @addRepo repo, data
    @emit "ResetRepos", @repos, data
  
  addRepo: (repo, data = {})->
    @repos.push repo
    @emit "AddRepo", repo, data # model, JSON

# Main View
class GitHub.Views.MainView extends JView

  {RepoView, AppRepoView, ReposView} = GitHub.Views
  
  constructor: ->
    super
    @github       = new Connector
    @storage      = Storage.getSingleton()
  
  # Element delegation
  delegateElements:->
    # Header View
    @header = new KDHeaderView
      type    : "big"
      title   : "Koding GitHub Dashboard"
    
    # Repo List
    @repoList = new ReposView
      viewOptions:
        itemClass: RepoView
    , items: []
        
    @repoList.on "AddRepo", (repo)=>
      @repoList.addItem repo
      
    @repoList.on "ResetRepos", (repos, {username})=>
      unless repos.length 
        notify "User #{username} has no repository. :("
      
    # Application Repo List
    @appRepoList = new ReposView
      viewOptions:
        itemClass: AppRepoView
    , items: []
    
    @appRepoList.on "AddRepo", (repo)=>
      @appRepoList.addItem repo
        
    @repoListView = @repoList.getView()
    @appRepoListView = @appRepoList.getView()
    
    # Username View
    @usernameField = new KDInputView
      placeholder     : "Write a GitHub username."
      defaultValue    : nickname
      validate        :
        event         : "keyup"
        rules         :
          required    : yes
    
    @usernameField.on "ValidationError",  => do @usernameButton.disable
    @usernameField.on "ValidationPassed", => do @usernameButton.enable
    
    # Clone URL View
    @cloneUrlField = new KDInputView
      placeholder     : "clone url."
      validate        :
        event         : "keyup"
        rules         :
          required    : yes
    
    @cloneUrlField.on "ValidationError",  => 
      do @cloneUrlButton.disable
      do @cloneUrlAppButton.disable
      
    @cloneUrlField.on "ValidationPassed", => 
      do @cloneUrlButton.enable
      do @cloneUrlAppButton.enable
    
    # Button View
    @usernameButton = new KDButtonView
      title       : "Get User Repositories"
      loader      :
        color   : "#000"
        diameter: 16
      callback    :=>
        
        username = @usernameField.getValue()
        
        @github.getRepos username, (error, repos)=>
          
          _repos = []
          _appRepos = []
          
          if error
            @usernameButton.hideLoader()
            clearTimeout @timeoutListener
            return notify error
            
          $.each repos, (i, repo)=>
            if repo.name.match /.kdapp$/
              _appRepos.push repo
            else
              _repos.push repo
        
          @repoList.resetRepos _repos, {username}
          @appRepoList.resetRepos _appRepos, {username}
          
          @usernameButton.hideLoader()
          clearTimeout @timeoutListener
          
        @timeoutListener = setTimeout => 
          notify "Something wrong..."
          @usernameButton.hideLoader()
        , Settings.requestTimeout
        
    # Button View
    @cloneUrlButton = new KDButtonView
      title       : "Clone URL"
      loader      :
        color   : "#000"
        diameter: 16
      callback    :=>
        
  pistachio: ->
    """
    {{> @header}}
    {{> @usernameField}}{{> @usernameButton}}
    <hr>
    {{> @appRepoListView}}
    {{> @repoListView}}
    """
  
  viewAppended: ->
    @delegateElements()
    @setTemplate do @pistachio
    @template.update()
        