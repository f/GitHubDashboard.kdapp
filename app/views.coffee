{Settings}                  = GitHub
{Connector, Storage, CLI}   = GitHub.Core
{Repo}                      = GitHub.Models

{notify}                    = GitHub.Core.Utils

{wait, killWait}            = KD.utils

class GitHub.Views.RepoView extends KDListItemView

  constructor: (options, @data)->
    options.cssClass = "repo-item"
    super
    @model = new Repo @data
    @action = if @data.fork then "Forked" else "Developed"
    
    @cloneButton = new KDButtonView
      cssClass   : "clean-gray clone"
      title      : "Clone Repository"
      callback   : =>
        notify "Cloning the #{@data.name} repository..."
            
        @model.clone ->
          notify "#{@data.name} successfully cloned."
    
  pistachio: ()->
    """
    <span class="name">#{@data.name}</span>
    <span class="owner">#{@action} by <a href="http://github.com/#{@data.owner.login}" target="_blank">
      #{@data.owner.login}</a></span>
    <div class="description">#{@data.description}</div>
    <code class="clone-url">$ git clone #{@data.clone_url}</code>
    {{> @cloneButton}}
    """
  
  viewAppended: ()->
    @setTemplate do @pistachio


class GitHub.Views.AppRepoView extends GitHub.Views.RepoView

  constructor: (options, @data)->
    super
    
    @model = new Repo @data
    
    @installButton = new KDButtonView
      cssClass   : "cupid-green install"
      title      : "Install Application"
      callback   : =>
        notify "Cloning the #{@data.name} repository as Koding App..."
          
        @model.cloneAsApp ->
          notify "#{@data.name} successfully cloned."
    
  pistachio: ()->
    """
    <img src="#{@data.__koding_icon}" width="128" height="128">
    <span class="name">#{@data.__koding_manifest.name}</span>
    <span class="owner">#{@action} by <a href="http://github.com/#{@data.owner.login}" target="_blank">
      #{@data.owner.login}</a></span>
    <div class="description">#{@data.__koding_manifest.description}</div>
    
    {{> @installButton}}
    {{> @cloneButton}}
    """
    
  viewAppended: ()->
    @setTemplate do @pistachio


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

    @placeholderView = new KDView
      cssClass: "placeholder"
      partial : """
                Hey! Just search for someone with GitHub username!
                """
    
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
    
    # The Generic Input View
    @theField = new KDInputView
      cssClass        : "username text"
      placeholder     : "Write a GitHub username or a repository URL to get started."
      validate        :
        event         : "keyup"
        rules         :
          required    : yes
    
    @theField.on "ValidationError",  => do @usernameButton.disable
    @theField.on "ValidationPassed", => do @usernameButton.enable
    
    # Button View
    @usernameButton = new KDButtonView
      cssClass    : "clean-gray username-button"
      title       : "Get User Repositories"
      loader      :
        color   : "#000"
        diameter: 16
      callback    :=>
        
        username = @theField.getValue()
        
        @github.getRepos username, (error, repos)=>
          
          _repos = []
          _appRepos = []
          
          if error
            @usernameButton.hideLoader()
            killWait @timeoutListener
            return notify error
            
          $.each repos, (i, repo)=>
            if repo.name.match /.kdapp$/
              @github.getAppRepoIconFullURL repo.name, (icon, manifest)=>
                repo.__koding_icon = icon
                repo.__koding_manifest = manifest
                _appRepos.push repo
                @appRepoList.resetRepos _appRepos, {username}
            else
              _repos.push repo
        
          @repoList.resetRepos _repos, {username}
                   
          wait 1200, => 
            @usernameButton.hideLoader()
            @placeholderView.hide()
            @containerView.show()
            
          killWait @timeoutListener
          
        @timeoutListener = wait Settings.requestTimeout, => 
          notify "Something wrong..."
          @usernameButton.hideLoader()
        
        
    @cloneUrlButton = new KDButtonView
      cssClass    : "clean-gray cloneurl-button"
      title       : "Clone Repository URL"
      callback    : =>
        notify "Coming Soon!"
    
    do @cloneUrlButton.disable
    do @usernameButton.disable
        
    @appRepoListView = new KDView
      cssClass: 'app-repo-list'
    @appRepoListView.addSubView @appRepoList.getView()
    
    @repoListView = new KDView
      cssClass: 'repo-list'
    @repoListView.addSubView @repoList.getView()
    
    @containerView = new KDView
      cssClass: 'repos'
    @containerView.hide()
      
    @containerView.addSubView @appRepoListView
    @containerView.addSubView @repoListView
        
  pistachio: ->
    """
    <div class="main-view">
      <header>
        <figure></figure>
        {{> @theField}}
        {{> @usernameButton}}
        {{> @cloneUrlButton}}
      </header>
      {{> @containerView}}
      {{> @placeholderView}}
    </div>
    """
  
  viewAppended: ->
    @delegateElements()
    @setTemplate do @pistachio
        