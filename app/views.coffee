{Settings}            = GitHub
{Connector, Storage}  = GitHub.Core
{Repo}                = GitHub.Models

{notify}              = GitHub.Core.Utils

class GitHub.Views.RepoView extends KDListItemView

  constructor: (options, @data)->
    options.cssClass = "repo-item"
    @model = new Repo @data
    
    super
    
  partial: ()->
    """
    #{@data.name} - <span>#{@data.clone_url}</span>
    <a href="#" class="clone-app">Clone as Koding App</a>
    <a href="#" class="clone">Clone</a>
    """

  # Should be more elegant.
  click: (e)->
    
    if e.target.className is "clone-app"
        
      notify "Cloning the #{@data.name} repository as Koding App..."
          
      @model.cloneAsApp =>
        notify "#{@data.name} successfully cloned."
        
    else if e.target.className is "clone"
    
      notify "Cloning the #{@data.name} repository..."
            
      @model.clone =>
        notify "#{@data.name} successfully cloned."

class GitHub.Views.ReposView extends KDListViewController

  # Empty repos
  repos: [],

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

  {RepoView, ReposView} = GitHub.Views
  
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
    
    @repoList = new ReposView
      viewOptions:
        itemClass: RepoView
    , items: []
        
    @repoList.on "AddRepo", (repo)=>
      @repoList.addItem repo

    @repoList.on "ResetRepos", (repos, {username})=>
      unless repos.length 
        notify "User #{username} has no repository. :("
        
    @repoListView = @repoList.getView()
    
    # Field View
    @usernameField = new KDInputView
      placeholder     : "Write a GitHub username."
      defaultValue    : nickname
      validate        :
        event         : "keyup"
        rules         :
          required    : yes
    
    @usernameField.on "ValidationError",  => do @usernameButton.disable
    @usernameField.on "ValidationPassed", => do @usernameButton.enable
    
    # Button View
    @usernameButton = new KDButtonView
      title       : "Get User Repositories"
      loader      :
        color   : "#000"
        diameter: 16
      callback    :=>
        
        username = @usernameField.getValue()
        
        @github.getRepos username, (error, repos)=>
          
          if error
            @usernameButton.hideLoader()
            clearTimeout @timeoutListener
            return notify error
        
          @repoList.resetRepos repos, {username}
          @usernameButton.hideLoader()
          clearTimeout @timeoutListener
          
        @timeoutListener = setTimeout => 
          notify "Something wrong..."
          @usernameButton.hideLoader()
        , Settings.requestTimeout
    
  pistachio: ->
    """
    {{> @header}}
    {{> @usernameField}}{{> @usernameButton}}
    <hr>
    {{> @repoListView}}
    """
  
  viewAppended: ->
    @delegateElements()
    @setTemplate do @pistachio
    @template.update()
        