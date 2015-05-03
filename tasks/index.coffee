gulp = require 'gulp'

gutil = require 'gulp-util'
runSequence = require 'run-sequence'

gulp.task 'default', (done) ->

  sequence = [
    ['browserify', 'stylus']
  ]

  if gutil.env.prod
    sequence.push 'exorcist'
    sequence.push 'version'

  runSequence sequence..., done

require './init'
require './browserify'
require './exorcist'
require './stylus'
require './version'

