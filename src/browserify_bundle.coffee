path = require 'path'
gulp = require 'gulp'
gutil = require 'gulp-util'
browserify = require 'browserify'
uglify = require 'gulp-uglify'
sourcemaps = require 'gulp-sourcemaps'
watchify = require 'watchify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
insertGlobals = require 'insert-module-globals'
addSrc = require 'gulp-add-src'
coffeeReactify = require 'coffee-reactify'
coffeeify = require 'coffeeify'
_ = require 'lodash'

module.exports = browserifyBundle = ({src, dest}, opts={}) ->
  assetConfig = require path.join(process.cwd(), 'Assetfile')

  console.warn('WARNING: sourcemaps in goodeggs-assets-cli have been disabled because they broke.')
  opts.sourcemaps = false

  args = _.defaults {}, opts.browserifyArgs,
    debug: opts.sourcemaps
    extensions: ['.coffee', '.cjsx']

  b = browserify src, args
  b.transform ((file) -> coffeeReactify(file, coffeeout: true)), global: true
  b.transform ((file) -> coffeeify(file)), global: true
  b.transform ((file) -> insertGlobals(file, basedir: process.cwd(), always: false, debug: opts.sourcemaps)), global: true # detectGlobals

  opts.beforeBundle?(b)

  bundleWithoutExtras = b.bundle.bind(b)
  b.bundle = (cb) ->
    cb = _.once cb
    bundleWithoutExtras()
      .on('error', cb)
      # Use vinyl-source-stream to make the
      # stream gulp compatible. Specify the
      # desired output filename here.
      .pipe(source(path.basename(dest)))
      .pipe(buffer())
      .pipe(opts.sourcemaps and sourcemaps.init(loadMaps: true) or gutil.noop())
      .pipe(opts.prepend and addSrc.prepend(opts.prepend) or gutil.noop())
      .pipe(opts.append and addSrc.append(opts.append) or gutil.noop())
      .pipe(opts.prod and uglify() or gutil.noop())
      .pipe(opts.sourcemaps and sourcemaps.write() or gutil.noop())
      .on('error', cb)
      .pipe(gulp.dest(path.dirname(dest)))
      .on('end', cb)

  return b
