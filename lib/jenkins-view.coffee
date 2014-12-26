JenkinsGateway = require './jenkins-gateway'
{View} = require 'atom'
rest = require 'restler'
xml2js = require 'xml2js'
BuildListView = require './build-list-view'

module.exports =
class JenkinsView extends View
  @content: ->
    @div class: 'jenkins inline-block', =>
      @div "Getting Jenkins Status...", class: "message", outlet: 'status'

  initialize: (serializeState) ->
    @failedBuilds = []
    atom.workspaceView.command "jenkins:list", ".editor", =>
      JenkinsGateway.getFailingBuilds (err, failingBuilds) =>
        @failedBuilds = failingBuilds
        @list()
    atom.workspaceView.command "jenkins:toggle", ".editor", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->


  # Tear down any state and detach
  destroy: ->
    @detach()

  list: ->
    if @failedBuilds.length > 0
      view = new BuildListView()
      panes = atom.workspaceView.getPaneViews()
      pane = panes[panes.length - 1].splitRight(@runnerView)
      pane.activateItem(view)
      window.test_pane = pane

      view.displayBuilds(@failedBuilds)
      view.scrollToBottom()

  toggle: ->
    if @hasParent()
      clearInterval(@ticker)
      @detach()
    else
      atom.workspaceView.statusBar.appendRight(this)
      @status.click (e) =>
        @list()

      @ticker = setInterval((=> @updateStatusBar()), 5000)
      @updateStatusBar()

  updateStatusBar: ->
    JenkinsGateway.getFailingBuilds (err, failedBuilds) =>
      if err
        console.error(err)

      @failedBuilds = failedBuilds

      if @failedBuilds.length > 0
        @status.html("<span>#{@failedBuilds.length} failing builds.</span>")
        @status.css("color", "red")
      else
        @status.text("All builds passing")
        @status.css("color", "green")
