gulp = require 'gulp'
path = require 'path'
exorcist = require 'exorcist'
transform = require 'vinyl-transform'

gulp.task 'exorcist', ->

  assetConfig = require path.join(process.cwd(), 'Assetfile')

  gulp.src(path.join(assetConfig.dest.dev, 'build/**/*.{css,js}'))
    .pipe(transform((file) ->
      exorcist "#{file}.map"
    ))
    .pipe(gulp.dest(path.join(assetConfig.dest.dev, 'build')))

