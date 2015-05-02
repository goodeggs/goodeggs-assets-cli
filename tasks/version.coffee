gulp = require 'gulp'

gulp.task 'version', ->
  path = require 'path'
  rev = require 'gulp-rev'
  revReplace = require 'gulp-rev-replace'
  assetConfig = require path.join(process.cwd(), 'Assetfile')

  gulp.src([path.join(assetConfig.dest.dev, '**/*'), "!#{path.join(assetConfig.dest.dev, '**/*.map')}"]) # don't publish sourcemaps
    .pipe(rev())
    .pipe(revReplace())
    .pipe(gulp.dest(assetConfig.dest.prod))
    .pipe(rev.manifest(path.basename(assetConfig.dest.manifest)))
    .pipe(gulp.dest(path.dirname(assetConfig.dest.manifest)))

