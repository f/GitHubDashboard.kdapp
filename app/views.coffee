{Settings}                  = GitHub
{Connector, Storage, CLI}   = GitHub.Core
{Repo}                      = GitHub.Models

{notify}                    = GitHub.Core.Utils

{wait, killWait}            = KD.utils

class GitHub.Views.RepoView extends KDListItemView

  constructor: (options, @data)->
    options.cssClass = "repo-item"
    @model = new Repo @data
    
    super
    
  partial: ()->
    """
    <span class="name">#{@data.name}</span>
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
    <img src="#{@data.__koding_icon}" width="128" height="128">
    <span class="name">#{@data.name}</span> 
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
  
  constructor:->
    super

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
        
    @repoList.on "AddRepo", (repo)=>
      @repoList.addItem repo
      
    @repoList.on "ResetRepos", (repos, {username})=>
      unless repos.length 
        notify "User #{username} has no repository. :("
      
    # Application Repo List
    @appRepoList = new ReposView
      viewOptions:
        itemClass: AppRepoView
    
    @appRepoList.on "AddRepo", (repo)=>
      @appRepoList.addItem repo
    
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
            killWait @timeoutListener
            return notify error
            
          $.each repos, (i, repo)=>
            if repo.name.match /.kdapp$/
              @github.getAppRepoIconFullURL repo.name, (icon)=>
                repo.__koding_icon = icon
                _appRepos.push repo
            else
              _repos.push repo
        
          @repoList.resetRepos _repos, {username}
          @appRepoList.resetRepos _appRepos, {username}
                   
          @usernameButton.hideLoader()
          killWait @timeoutListener
          
        @timeoutListener = wait Settings.requestTimeout, => 
          notify "Something wrong..."
          @usernameButton.hideLoader()
        
    # Button View
    @cloneUrlButton = new KDButtonView
      title       : "Clone URL"
      loader      :
        color   : "#000"
        diameter: 16
      callback    :=>
        
    @appRepoListView = new KDView
      cssClass: 'app-repo-list'
    @appRepoListView.addSubView @appRepoList.getView()
    
    @repoListView = new KDView
      cssClass: 'repo-list'
    @repoListView.addSubView @repoList.getView()
    
    @containerView = new KDView
      cssClass: 'repos'
      
    @containerView.addSubView new KDHeaderView
      type: 'medium'
      title: 'Koding Applications'
    @containerView.addSubView @appRepoListView
    
    @containerView.addSubView new KDHeaderView
      type: 'medium'
      title: 'Repositories'
    @containerView.addSubView @repoListView
        
  pistachio: ->
    """
    {{> @header}}
    {{> @usernameField}}{{> @usernameButton}}
    <hr>
    {{> @containerView}}
    """
  
  viewAppended: ->
    @delegateElements()
    @setTemplate do @pistachio
        