# 
# The brute way:
#   __c = document.createElement 'iframe'; __c.src = "about:blank"
#   document.body.appendChild __c; console = __c.contentWindow.console
#
# The kind way:
#   KD.enableLogs()

# KD.enableLogs()

# Base Hierarchy
# Defining all the namespaces here, to make the app more readable.

GitHub =
    # Settings
    Settings:
        baseViewClass: 'github-dashboard'
        appStorageName: 'github-dashboard'
        # Timeout of request
        requestTimeout: 15000
        
    ##############
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