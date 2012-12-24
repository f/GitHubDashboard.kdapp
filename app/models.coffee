# Use GitHub.Core.CLI as CLI
{CLI} = GitHub.Core

class GitHub.Models.Repo

  constructor: (@data) ->
    @cli = CLI.getSingleton()
  
  clone: (callback)->
    @cli.clone @data.clone_url, @data.name, callback

  cloneAsApp: (callback)->
    @cli.cloneAsApp @data.clone_url, @data.name, callback