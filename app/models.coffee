# Use GitHub.Core.CLI as CLI
{CLI} = GitHub.Core

class GitHub.Models.Repo

  constructor: (@model) ->
    @cli = CLI.getSingleton()
  
  clone: (callback)->
    @cli.clone @model.clone_url, @model.name, callback

  cloneAsApp: (callback)->
    console.log @model.__koding_manifest.path
    if @model.__koding_manifest.path
      match = @model.__koding_manifest.path.match /\/([^\/]*).kdapp\/?$/
      if match
        name = match[1]
      else
        name = @model.name
    else
      name = @model.name
      
    @cli.cloneAsApp @model.clone_url, name, callback