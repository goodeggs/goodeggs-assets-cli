require 'mocha-sinon'
expect = require('chai').expect
tmp = require 'tmp'
path = require 'path'
{exec} = require 'child_process'
fs = require 'fs'

binPath = path.resolve(__dirname, '../bin/goodeggs-assets.js')

describe 'goodeggs-assets', ->

  before (done) ->
    tmp.dir 'goodeggs-assets-cli', (err, dir) ->
      process.chdir dir
      done(err)

  describe 'init', ->

    before (done) ->
      exec "#{binPath} init", done

    it 'creates an Assetfile.coffee', ->
      expect(fs.existsSync('./Assetfile.coffee')).to.be.true

