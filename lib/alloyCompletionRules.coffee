fs = require('fs')
tagRegExp =  /(<([^>]+)>)/ig
util = require './ti-pkg-util'
related = require './related'
_ = require 'underscore'
find = require 'find'
path = require 'path'
parseString = require('xml2js').parseString;
getLine = util.getLine
find = require 'find'

module.exports = {
  cfg: {
    regExp : /Alloy\.CFG\.([-a-zA-Z0-9-_\/]*)$/
    getCompletions : (request) ->
      completions = undefined
      line = getLine(request)
      
      if @regExp.test(line)
        cfgPath = path.join(util.getAlloyRootPath(),'config.json')
        cfgKeys = []
        completions = []
        if util.isExistAsFile cfgPath
          try
            # merge ally evn and platform(os) keys
            cfgObj = JSON.parse(util.getFileEditor(cfgPath).getText())
            cfgObj = _.reduce(cfgObj, (memo, value, key) ->
              if key is "global" or key.startsWith('env:') or key.startsWith('os:')
                return _.extend(memo,value)
              else
                return memo;
            , {})
            
            allKeys = util.getAllKeys(cfgObj)
            
            for key in allKeys
              completions.push
                text: key
                type: 'variable'
                
                # leftLabel : defaultLang
                # rightLabel: value._
                # replacementPrefix : util.getCustomPrefix(request)
                # description : value._
                # 
          catch error
            console.log error
          
      
      
      return completions
    
  },
  i18n : {
    # regExp : /L\(["']([-a-zA-Z0-9-_\/]*)$/
    regExp : /L\(["']([^\s\\\(\)"':,;<>~!@\$%\^&\*\|\+=\[\]\{\}`\?\…]*)$/
    getCompletions : (request) ->
      completions = undefined
      line = getLine(request)
      alloyRootPath = util.getAlloyRootPath()
      if @regExp.test(line)
        defaultLang = atom.config.get('titanium-alloy.defaultI18nLanguage')
        i18nStringPath = path.join(util.getI18nPath(),defaultLang,"strings.xml")
        
        completions = []
        if util.isExistAsFile(i18nStringPath)
          parseString(util.getFileEditor(i18nStringPath).getText(), (error,result) ->
            _.each(result?.resources?.string || [], (value) ->
              completions.push 
                text: value.$.name
                leftLabel : defaultLang
                rightLabel: value._
                type: 'variable'
                replacementPrefix : util.getCustomPrefix(request)
                description : value._
              
              # completions.push 
              #   snippet: "x${0:#{value._}}#{value.$.name}"
              #   displayText: "#{value._}"
              #   leftLabel : defaultLang
              #   rightLabel: value.$.name
              #   type: 'value'
              #   replacementPrefix : util.getCustomPrefix(request)
              #   
              
              # i18n key finder로 개별 package 고려
              
              )
          )
      return completions
  },
  path : {
    regExp : /["']\/i([-a-zA-Z0-9-_\/]*)$/
    getCompletions : (request) ->
      {prefix} = request
      completions = undefined
      line = getLine(request)
      alloyRootPath = util.getAlloyRootPath()
      assetPath = path.join(alloyRootPath,'assets')
      imgPath = path.join(assetPath,'images')
      
      if @regExp.test(line) and util.isExistAsDirectory(imgPath)
        completions = []
        files = find.fileSync imgPath
        for file in files
          # if currentPath != file # exclude current controller
          continue if file.endsWith('.DS_Store')
          continue if file.includes('@')
          completions.push
            text: util.toUnixPath(file.replace(assetPath,''))
            type: 'file',
            replacementPrefix : util.getCustomPrefix(request)
            iconHTML : "<image style='background-position: center; background-repeat: no-repeat; background-size: contain; background-image: url(#{file}); height:29px; width:29px; '></image>"
      return completions
  }
}
