# alias Models
{Connector}     = GitHub.Core
{Repo}          = GitHub.Models

GITHUB_TIMEOUT = 15000

class GitHub.Views.RepoView extends KDListItemView

    constructor: ->
      super

    partial: (data)-> """
        #{data.name} - #{data.clone_url} 
        <a class='clone' href='#'>Clone</a> - <a class='clone-app' href='#'>Clone as Koding App</a>
    """

    click: (e)->
        model = new Repo @getData()

        if e.target.className is  "clone-app"
            
            new KDNotificationView
                title: "Cloning the #{@getData().name} repository as Koding App..."
                
            model.cloneAsApp()
            
        else if e.target.className is "clone"
        
            new KDNotificationView
                title: "Cloning the #{@getData().name} repository..."
                
            model.clone()         
    
class GitHub.Views.ReposView extends KDListView
    
class GitHub.Views.MainView extends JView

    {RepoView, ReposView} = GitHub.Views
    
    constructor:->
        super
        @github = new Connector
        @repoListView = new ReposView     
    
    viewAppended:->
        
        # Adding Header
        header = new KDHeaderView
            type    : "big"
            title   : "Koding GitHub Dashboard"
            
        usernameField = new KDInputView
            placeholder         : "Write a GitHub username."
            validate            :
                event           : "keyup"
                rules           :
                    required    : yes
        
                
        usernameField.on "ValidationError",  -> do usernameButton.disable
        usernameField.on "ValidationPassed", -> do usernameButton.enable
        
        usernameButton = new KDButtonView
            title       : "Get User Repositories"
            loader      :
                color   : "#000"
                diameter: 16
            callback    :=>                
                @github.getRepos usernameField.getValue(), (repos)=>
                    @classListController = new KDListViewController
                        viewOptions :
                            itemClass : RepoView
                    ,
                        items : (repo for repo in repos when typeof repo is "object")
                    @addSubView @classListController.getView()
                    usernameButton.hideLoader()
                    clearTimeout @timeoutListener
                    
                @timeoutListener = setTimeout (->
                    
                    new KDNotificationView
                        title: "Something wrong..."
                        
                    usernameButton.hideLoader()
                ), GITHUB_TIMEOUT
                    
        do usernameButton.disable
        
        @addSubView header
        @addSubView usernameField
        @addSubView usernameButton
        