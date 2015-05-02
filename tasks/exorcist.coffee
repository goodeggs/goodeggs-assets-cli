gulp = require 'gulp'

gulp.task 'exorcist', ->
  path = require 'path'
  exorcist = require 'exorcist'
  transform = require 'vinyl-transform'
  assetConfig = require path.join(process.cwd(), 'Assetfile')

  gulp.src(path.join(assetConfig.dest.dev, 'build/**/*.{css,js}'))
    .pipe(transform((file) ->
      exorcist "#{file}.map"
    ))
    .pipe(gulp.dest(path.join(assetConfig.dest.dev, 'build')))

