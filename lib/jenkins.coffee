JenkinsView = require './jenkins-view'

module.exports =
  configDefaults:
    username: ''
    password: ''
    url: ''

  jenkinsView: null

  activate: (state) ->
    @jenkinsView = new JenkinsView(state.jenkinsViewState)

  deactivate: ->
    @jenkinsView.destroy()

  serialize: ->
    jenkinsViewState: @jenkinsView.serialize()
