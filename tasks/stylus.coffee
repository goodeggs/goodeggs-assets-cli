gulp = require 'gulp'

path = require 'path'
stylus = require 'gulp-stylus'
sourcemaps = require 'gulp-sourcemaps'
rename = require 'gulp-rename'
gutil = require 'gulp-util'
nib = require('nib')()

gulp.task 'stylus', ->

  assetConfig = require path.join(process.cwd(), 'Assetfile')

  stylusStreamer = stylus
    compress: true
    use: [nib]

  gulp.src(assetConfig.css.entrypoints, base: 'src')
    .pipe(sourcemaps.init())
    .pipe(stylusStreamer)
    .pipe(sourcemaps.write())
    .pipe(rename((parts) ->
      # ui-pages/welcome_page/index.css -> ui-pages/welcome_page.css
      parts.basename = path.basename(parts.dirname)
      parts.dirname = path.dirname(parts.dirname)
      parts
    ))
    .pipe(gulp.dest(path.join(assetConfig.dest.dev, 'build/css')))

  if !gutil.env.prod
    gulp.watch assetConfig.css.entrypoints, ['stylus']

