{View} = require 'atom'
JenkinsGateway = require './jenkins-gateway'
rest = require 'restler'
xml2js = require 'xml2js'
BuildListView = require './build-list-view'

module.exports =
class JenkinsView extends View
  @content: ->
    @div class: 'jenkins inline-block', =>
      @div class: "status inline-block requesting", outlet: 'status'

  initialize: (serializeState) ->
    @failedBuilds = []

    if not serializeState or serializeState.isActive
      atom.packages.once 'activated', => @toggle()

    atom.workspaceView.command "jenkins:list", ".editor", =>
      JenkinsGateway.getFailingBuilds (err, failingBuilds) =>
        @failedBuilds = failingBuilds
        @list()
    atom.workspaceView.command "jenkins:toggle", ".editor", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->
    isActive: @isActive

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
    @isActive = !@isActive
    if @hasParent()
      clearInterval(@ticker)
      @detach()
    else
      atom.workspaceView.statusBar.appendLeft(this)
      @status.click (e) =>
        @list()

      @ticker = setInterval((=> @updateStatusBar()), atom.config.get('jenkins.interval'))
      @updateStatusBar()

  updateStatusBar: ->
    JenkinsGateway.getFailingBuilds (err, failedBuilds) =>
      if err
        @status.attr('title', err.toString())
        console.error(err)
      else
        @failedBuilds = failedBuilds

        if @failedBuilds.length > 0
          @status
            .removeClass('requesting success')
            .addClass('error pointer')
            .attr('title', '#{@failedBuilds.length} failing builds.')
        else
          @status
            .removeClass('requesting error')
            .addClass('success')
            .attr('title', 'All builds passing.')
