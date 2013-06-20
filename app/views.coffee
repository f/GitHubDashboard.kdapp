{Settings}                  = GitHub
{Connector, Storage, CLI}   = GitHub.Core
{Repo}                      = GitHub.Models

{notify}                    = GitHub.Core.Utils

{wait, killWait}            = KD.utils

class GitHub.Views.RepoView extends KDListItemView

  constructor: (options, @data)->
    options.cssClass = "repo-item"
    super
    @storage = Storage.getSingleton()

    @model = new Repo @data
    @action = if @data.fork then "Forked" else "Developed"
    
    @cloneButton = new KDButtonView
      cssClass   : "clean-gray clone"
      title      : "Clone Repository"
      callback   : =>
        notify "Cloning the #{@data.name} repository..."
            
        @model.clone =>
          wait 300, => notify "#{@data.name} successfully cloned."
          @pushClonedRepo @data
          
  partial: -> 
  pistachio: ()->
    """
    <span class="name">#{@data.name}</span>
    <span class="owner">#{@action} by <a href="http://github.com/#{@data.owner.login}" target="_blank">
      #{@data.owner.login}</a></span>
    <div class="description">#{@data.description}</div>
    <code class="clone-url">$ git clone #{@data.clone_url}</code>
    {{> @cloneButton}}
    """
    
  pushClonedRepo: (repo)->
    @storage.get "repos", (data)=>
      data or= []
      data.push repo
      @storage.set "repos", data
      
  pushClonedAppRepo: (repo)->
    @storage.get "appRepos", (data)=>
      data or= []
      data.push repo
      @storage.set "appRepos", data
  
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
        warning = new KDModalView
          title  : "Security Warning"
          overlay: yes
          content: """
          <div class='modalformline'>
            <p>
              Installing apps from outside of Koding AppStore could be <strong>dangerous</strong>.
              This app can reach (and modify) all of your files, settings and all other 
              information you shared with Koding. If you don't know what you are doing, 
              it's not <strong>recommended</strong> to install apps from outside of Koding AppStore.
            </p>
            <p>
              Do you want to continue to install this app from #{@data.clone_url}?
            </p>
          </div>
          """
          buttons: 
            "Yes, I know the risks":
              loader   :
                color  : "#000"
                diameter: 16
              style    : "modal-clean-gray"
              callback : =>
                          
                notify "Installing #{@data.__koding_manifest.name}..."
                  
                @model.cloneAsApp =>
                  wait 300, => notify "#{@data.__koding_manifest.name} successfully installed."
                  warning.destroy()
                  @pushClonedAppRepo @data
    
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
    @storage 
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
    
  getExistingRepos: (callback)->
    
    @storage.get "appRepos", (storedAppRepos)=>
      if storedAppRepos.length
        @appRepoList.resetRepos storedAppRepos
    
      @storage.get "repos", (storedRepos)=>
        if storedRepos.length
          @repoList.resetRepos storedRepos
        wait 1200, => 
          @placeholderView.hide()
          @containerView.show()
          do callback if callback
            
  
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
      if username
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
      enterKeyEnabled : yes
      type            : "text"
      cssClass        : "username text"
      placeholder     : "Write a GitHub username or a repository URL to get started."
      validate        :
        event         : "keyup"
        rules         :
          required    : yes
    
    @theField.on "keyup", (event)=>
      if event.keyCode is 13
        @usernameButton.$().click()
    
    @theField.on "ValidationError",  => 
      do @cloneUrlButton.disable
      do @usernameButton.disable
    @theField.on "ValidationPassed", => 
      do @cloneUrlButton.enable
      do @usernameButton.enable
    
    # Button View
    @usernameButton = new KDButtonView
      cssClass    : "clean-gray username-button"
      title       : "Get User Repositories"
      loader      :
        color   : "#000"
        diameter: 16
      callback    :=>
        
        [username, repoName] = @theField.getValue().split "/"
        
        @appRepoList.replaceAllItems []
        @repoList.replaceAllItems []
        @placeholderView.show()
        
        console.log @placeholderView
        
        @github.getRepos username, (error, repos)=>
          
          _repos = []
          _appRepos = []
          
          if error
            @usernameButton.hideLoader()
            killWait @timeoutListener
            return notify error
            
          $.each repos, (i, repo)=>
            if repoName and repo.name isnt repoName
              @appRepoList.resetRepos [], {username}
              return
            
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
    
    # @getExistingRepos()
    
    @dashboardButton = new KDButtonView
      cssClass          : "clean-gray cloneurl-button"
      title             : "Dashboard"
      loader            :
        color           : "#000"
        diameter        : 16
      callback          : => 
        @getExistingRepos =>
          @dashboardButton.hideLoader()
    
    @cloneUrlButton = new KDButtonView
      cssClass          : "clean-gray cloneurl-button"
      title             : "Clone Repository URL"
      callback          : =>
        
        cli = CLI.getSingleton()
        
        repoPath = @theField.getValue()
        repoUrl = repoPath.replace /(https?:\/\/)?github.com\/(.*)\/(.*)/, "$2/$3"
        [repoUser, repoName] = repoUrl.split "/"
        
        unless repoUser and repoName
          notify "This is not a clone URL, sorry. :("
          return
          
        modal = new KDModalViewWithForms
          title         : "Clone Repository URL"
          content       : "<div class='modalformline'>Please write a name to clone the repository.</div>"
          overlay       : yes
          tabs          :
            forms       :
              form      :
                fields  :
                  "User":
                    label    : "Repository"
                    name     : "repoUrl"
                    defaultValue: "https://github.com/#{repoUrl}"
                    disabled : yes
                  "Root":
                    label    : "Clone Root"
                    name     : "root"
                    defaultValue: "/Users/#{nickname}/GitHub/"
                    disabled : yes
                  "Path":
                    label    : "Clone Path"
                    name     : "root"
                    defaultValue: "#{repoName}"
                    
                buttons : 
                  "Clone the Repository":
                    loader   :
                      color  : "#000"
                      diameter: 16
                    style    : "modal-clean-gray"
                    callback : =>
                      notify "Cloning #{repoName} repository."
                      cloneUrl = "https://github.com/#{repoUrl}"
                      clonePath = modal.modalTabs.forms.form.inputs.Path.getValue()
                      
                      cli.clone cloneUrl, clonePath, =>
                        notify "Cloned #{repoName} repository successfully!"
                        modal.modalTabs.forms.form.buttons["Clone the Repository"].hideLoader()
                        modal.destroy()
                
    
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
    <div class="scrollfade"></div>
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