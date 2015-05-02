gulp = require 'gulp'

gulp.task 'browserify', (cb) ->
  path = require 'path'
  browserify = require 'browserify'
  watchify = require 'watchify'
  gutil = require 'gulp-util'
  source = require 'vinyl-source-stream'
  rename = require 'gulp-rename'
  insertGlobals = require 'insert-module-globals'
  addSrc = require 'gulp-add-src'

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
    b.transform 'coffee-reactify', global: true, coffeeout: true
    b.transform 'coffeeify', global: true
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
      b.bundle()
        # Report compile errors
        .on('error', gutil.log.bind(gutil))
        # Use vinyl-source-stream to make the
        # stream gulp compatible. Specify the
        # desired output filename here.
        .pipe(source(dest))
        .pipe(addSrc.prepend(opts.prepend ? ''))
        .pipe(addSrc.append(opts.append ? ''))
        .pipe(rename((parts) ->
          parts.basename = path.basename(parts.dirname)
          parts.dirname = path.dirname(parts.dirname)
          parts.extname = '.js'
          parts
        ))
        # Specify the output destination
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

