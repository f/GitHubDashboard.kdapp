# Use GitHub.Core.CLI as CLI
{CLI} = GitHub.Core

class GitHub.Models.Repo

  constructor: (@model) ->
    @cli = CLI.getSingleton()
  
  clone: (callback)->
    @cli.clone @model.clone_url, @model.name, callback

  cloneAsApp: (callback)->
    @cli.cloneAsApp @model.clone_url, @model.name, callback