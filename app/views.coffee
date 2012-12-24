{Settings}            = GitHub
{Connector, Storage}  = GitHub.Core
{Repo}                = GitHub.Models

{notify}              = GitHub.Core.Utils

class GitHub.Views.RepoView extends JView

  constructor: (@model)->
    alert JSON.stringify @getData()
  ###
  click: (e)->
    alert 1
    no
    model = new Repo @getData()

    if e.target.className is  "clone-app"
        
      notify "Cloning the #{@getData().name} repository as Koding App..."
          
      model.cloneAsApp =>
        notify "#{@getData().name} successfully cloned."
        
    else if e.target.className is "clone"
    
      notify "Cloning the #{@getData().name} repository..."
            
      model.clone =>
        notify "#{@getData().name} successfully cloned."
  ###

class GitHub.Views.ReposView extends JView

  # Empty repos
  repos: []

  resetRepos: (repos, data)->
    $.each repos, (repo)=>
      @addRepo repo
    @emit "ResetRepos", @repos, data
  
  addRepo: (repo, data)->
    _repo = new Repo repo
    @repos.push _repo
    @emit "AddRepo", _repo, repo, data # model, JSON
    
  viewAppended:->

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
    @repoList.on "AddRepo", (repo)=>
      repoView = new RepoView repo
    
    @repoList.on "ResetRepos", (repos, {username})->
      unless repos.length then notify "User #{username} has no repository. :("
    
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
        
        @github.getRepos username, (repos)=>
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
    {{> @repoList}}
    """
  
  viewAppended: ->
    @delegateElements()
    @setTemplate do @pistachio
        