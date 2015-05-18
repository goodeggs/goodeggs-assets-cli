gulp = require 'gulp'

fs = require 'fs'
path = require 'path'

gulp.task 'init', ->

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

  rollbar:
    accessToken: process.env.ROLLBAR_ACCESS_TOKEN
    version: process.env.ECRU_COMMIT

  hosts: [
    # '//your.site.or.cdn'
  ]

'''
