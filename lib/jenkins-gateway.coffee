{View} = require 'atom'
rest = require 'restler'
xml2js = require 'xml2js'
_ = require "lodash"

_checkConfig = () ->
  atom.config.get('jenkins.username') &&
  atom.config.get('jenkins.password') &&
  atom.config.get('jenkins.ccxmlUrl')

_get = (url, cb) ->
  options = {
    username: atom.config.get('jenkins.username'),
    password: atom.config.get('jenkins.password')
  }

  rest.get(url, options).on 'complete', (data) =>
    cb(data)

module.exports = {
  getBuildOutput: (url, cb) ->
    if !_checkConfig()
      cb("please define jenkins.username, jenkins.password, and jenkins.ccxmlUrl in your atom config file.", "")
    else
      _get url, (data) ->
        cb(undefined, data)

  getFailingBuilds: (cb) ->
    if !_checkConfig()
      cb("please define jenkins.username, jenkins.password, and jenkins.ccxmlUrl in your atom config file.", [])
      return

    failedBuilds = []

    #_get "https://ci.braintreepayments.com/view/Venmo%20Touch/cc.xml", (data) ->
    _get atom.config.get("jenkins.ccxmlUrl"), (data) ->
      xml2js.parseString data, (err, result) =>
        if err
          console.log(err)
          console.log(data)
          cb("failed to reach jenkins.ccxmlUrl #{atom.config.get("jenkins.ccxmlUrl")}", [])
        else
          _(result.Projects.Project).forEach (project) =>
            if project.$.lastBuildStatus != "Success"
              failedBuilds.push(project.$)
          cb(undefined, failedBuilds)
}
