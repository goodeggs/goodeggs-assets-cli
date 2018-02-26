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
      console.log('working directory', dir)
      process.chdir dir
      exec 'yarn add coffee-script lodash', (err, stdout, stderr) ->
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
        it 'has versioned javascript endpoint files', ->
          expect(fs.existsSync('./build/public/build/js/components/welcome-373e1652.js')).to.be.true

        it 'does not have unversioned javascript endpoint files', ->
          expect(fs.existsSync('./build/public/build/js/components/welcome.js')).to.be.false

        it 'has versioned javascript external files', ->
          expect(fs.existsSync('./build/public/build/js/ext/thirdparty-287b2a83.js')).to.be.true

        it 'has a manifest', ->
          expect(fs.existsSync('./build/rev-manifest.json')).to.be.true

        it 'javascript does not have inline sourcemaps', ->
          expect(fs.readFileSync('./build/public/build/js/components/welcome-373e1652.js', 'utf8')).not.to.contain 'sourceMappingURL=data'

        it 'does not have external sourcemaps', ->
          expect(fs.existsSync('./build/public/build/js/components/welcome.js.map')).to.be.false
          expect(fs.existsSync('./build/public/build/js/components/welcome-373e1652.js.map')).to.be.false

        describe 'the manifest', ->
          {manifest} = {}

          before ->
            manifest = JSON.parse(fs.readFileSync('./build/rev-manifest.json', 'utf8'))

          it 'is valid', ->
            expect(manifest['build/js/components/welcome.js']).to.equal 'build/js/components/welcome-373e1652.js'

      describe '/public/build', ->

        it 'has javascript endpoint files', ->
          expect(fs.existsSync('./public/build/js/components/welcome.js')).to.be.true

        it 'has javascript endpoint sourcemaps', ->
          expect(fs.existsSync('./public/build/js/components/welcome.js.map')).to.be.true

        it 'has javascript external files', ->
          expect(fs.existsSync('./public/build/js/ext/thirdparty.js')).to.be.true

        it 'has javascript external sourcemaps', ->
          expect(fs.existsSync('./public/build/js/ext/thirdparty.js.map')).to.be.true

        it 'has css files', ->
          expect(fs.existsSync('./public/build/css/components/welcome.css')).to.be.true

        it 'has css sourcemaps', ->
          expect(fs.existsSync('./public/build/css/components/welcome.css.map')).to.be.true

    describe 'with hosts', ->

      before ->
        fs.appendFileSync './Assetfile.coffee', '''\n  hosts: ['//1.example.com', '//2.example.com']\n''', 'utf8'

      describe 'version', ->

        before (done) ->
          exec "#{binPath} version", (err, stdout, stderr) ->
            console.log stdout, stderr if err?
            done(err)

        describe 'the manifest', ->
          {manifest} = {}

          before ->
            manifest = JSON.parse(fs.readFileSync('./build/rev-manifest.json', 'utf8'))

          it 'distributes assets across hosts', ->
            expect(manifest['build/js/components/welcome.js']).to.equal '//1.example.com/build/js/components/welcome-373e1652.js'
            expect(manifest['build/css/components/welcome.css']).to.equal '//2.example.com/build/css/components/welcome-f1468acf.css'

