gulp = require 'gulp'
path = require 'path'
browserify = require 'browserify'
uglify = require 'gulp-uglify'
sourcemaps = require 'gulp-sourcemaps'
watchify = require 'watchify'
gutil = require 'gulp-util'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
insertGlobals = require 'insert-module-globals'
addSrc = require 'gulp-add-src'
coffeeReactify = require 'coffee-reactify'
coffeeify = require 'coffeeify'

gulp.task 'browserify', (cb) ->

  assetConfig = require path.join(process.cwd(), 'Assetfile')

  devMode = !gutil.env.prod
  bundleQueue = 0

  browserifyEntrypoint = (entrypoint, externals=[]) ->
    browserifyThis src: entrypoint.path, dest: entrypoint.relative,
      beforeBundle: (b) ->
        b.require(entrypoint.path, expose: path.dirname(entrypoint.relative))
        b.external(external) for external in externals

  browserifyExternal = (name, bundleConfig) ->
    browserifyThis src: null, dest: "ext/#{name}/index.js",
      prepend: bundleConfig.prepend
      append: bundleConfig.append
      beforeBundle: (b) ->
        b.require(name) for name in bundleConfig.require or []

  browserifyThis = ({src, dest}, opts={}) ->
    bundleQueue++

    args = {}
    args[k] = v for k, v of watchify.args if devMode
    args.debug = true # sourcemaps
    args.extensions = ['.coffee', '.cjsx']

    b = browserify src, args
    b.transform ((file) -> coffeeReactify(file, coffeeout: true)), global: true
    b.transform ((file) -> coffeeify(file)), global: true
    b.transform ((file) -> insertGlobals(file.path, always: false)), global: true # detectGlobals

    opts.beforeBundle?(b)

    initialCbGate = ->
      cb() if --bundleQueue is 0

    bundleLogger = ->
      startedAt = Date.now()
      gutil.log "Starting '#{gutil.colors.cyan("browserify #{dest}")}'..."
      return ->
        duration = Date.now() - startedAt
        gutil.log "Finished '#{gutil.colors.cyan("browserify #{dest}")}' after #{gutil.colors.magenta("#{duration} ms")}"

    bundle = ->
      done = bundleLogger()
      dest = "#{path.dirname(path.dirname(dest))}/#{path.basename(path.dirname(dest))}.js"
      b.bundle()
        .on('error', (err) -> gutil.log(gutil.colors.red('[browserify]', err.message)); @emit 'end')
        # Use vinyl-source-stream to make the
        # stream gulp compatible. Specify the
        # desired output filename here.
        .pipe(source(dest))
        .pipe(buffer())
        .pipe(sourcemaps.init(loadMaps: true))
        .pipe(opts.prepend and addSrc.prepend(opts.prepend) or gutil.noop())
        .pipe(opts.append and addSrc.append(opts.append) or gutil.noop())
        .pipe(devMode and gutil.noop() or uglify())
        .pipe(sourcemaps.write())
        .on('error', gutil.log)
        .pipe(gulp.dest(path.join(assetConfig.dest.dev, 'build/js')))
        .on('end', done)
        .on('end', initialCbGate)

    if devMode
      # Wrap with watchify and rebundle on changes
      b = watchify(b)
      b.on 'update', bundle

    bundle()
    return b

  # first the externals
  externals = (browserifyExternal(name, config) for name, config of assetConfig.js.externals or {})

  # then all our entrypoints
  gulp.src(assetConfig.js.entrypoints, base: 'src', read: false)
    .on 'data', (entrypoint) -> browserifyEntrypoint entrypoint, externals

  return # don't return the stream above

