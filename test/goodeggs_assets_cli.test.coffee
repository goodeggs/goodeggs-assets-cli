require 'mocha-sinon'
expect = require('chai').expect
tmp = require 'tmp'
path = require 'path'
{exec} = require 'child_process'
fs = require 'fs'
ms = require 'to-ms'

binPath = path.resolve(__dirname, '../bin/goodeggs-assets.js')

describe 'goodeggs-assets', ->
  @timeout ms.minutes(10)

  before (done) ->
    tmp.dir 'goodeggs-assets-cli', (err, dir) ->
      return done(err) if err?
      process.chdir dir
      exec 'npm install coffee-script lodash', (err, stdout, stderr) ->
        console.log stdout, stderr if err?
        done(err)

  describe 'with an empty dir', ->

    describe 'init', ->

      before (done) ->
        exec "#{binPath} init", (err, stdout, stderr) ->
          console.log stdout, stderr if err?
          done(err)

      it 'creates an Assetfile.coffee', ->
        expect(fs.existsSync('./Assetfile.coffee')).to.be.true

  describe 'with a simple Assetfile', ->

    before ->
      fs.writeFileSync './Assetfile.coffee', '''
        module.exports =
          css:
            entrypoints: 'src/components/**/index.styl'
          js:
            entrypoints: 'src/components/**/index.cjsx'
            externals:
              thirdparty:
                require: ['lodash']
          dest:
            dev: 'public'
            prod: 'build/public'
            manifest: 'build/rev-manifest.json'
      ''', 'utf8'
      fs.mkdirSync './src'
      fs.mkdirSync './src/components'
      fs.mkdirSync './src/components/welcome'
      fs.writeFileSync './src/components/welcome/index.cjsx', '''
        lodash = require 'lodash'
        class Welcome extends React.Component
          render: ->
            <div className="bob" />
        module.exports = Welcome
      ''', 'utf8'
      fs.writeFileSync './src/components/welcome/index.styl', '''
        html
          background red
          color black
      ''', 'utf8'

    describe '--prod', ->

      before (done) ->
        exec "#{binPath} --prod", (err, stdout, stderr) ->
          console.log stdout, stderr if err?
          done(err)

      describe '/build directory', ->
        it 'has versioned javascript files'
        it 'javascript does not have inline sourcemaps'
        it 'does not have external sourcemaps'

      describe '/public/build', ->

        it 'has javascript files', ->
          expect(fs.existsSync('./public/build/js/components/welcome.js')).to.be.true

        it 'has javascript sourcemaps', ->
          expect(fs.existsSync('./public/build/js/components/welcome.js.map')).to.be.true

        it 'has css files', ->
          expect(fs.existsSync('./public/build/css/components/welcome.css')).to.be.true

        it 'has css sourcemaps', ->
          expect(fs.existsSync('./public/build/css/components/welcome.css.map')).to.be.true

