gulp = require 'gulp'

gulp.task 'init', ->
  fs = require 'fs'
  path = require 'path'

  assetfilePath = path.join(process.cwd(), 'Assetfile.coffee')

  if fs.existsSync(assetfilePath)
    throw new Error "Assetfile.coffee already exists!"

  fs.writeFileSync assetfilePath, TEMPLATE, 'utf8'
  console.log 'wrote Assetfile.coffee'


TEMPLATE = '''
module.exports =

  css:
    entrypoints: 'src/ui-pages/*/index.styl'

  js:
    entrypoints: 'src/ui-pages/*/index.{coffee,cjsx}'

    externals:
      thirdparty:
        # modules that will be available to but excluded from the entrypoints
        require: [
          'react'
        ]
        # prepend: same args as gulp.src
        # append: ditto

  dest:
    dev: 'public'
    prod: 'build/public'
    manifest: 'build/rev-manifest.json'
'''
