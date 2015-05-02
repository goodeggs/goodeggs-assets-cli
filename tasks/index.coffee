gulp = require 'gulp'

require './init'
require './browserify'
require './exorcist'
require './stylus'
require './version'

gulp.task 'default', (done) ->
  gutil = require 'gulp-util'
  runSequence = require 'run-sequence'

  sequence = [
    ['browserify', 'stylus']
  ]

  if gutil.env.prod
    sequence.push 'exorcist'
    sequence.push 'version'

  runSequence sequence..., done

