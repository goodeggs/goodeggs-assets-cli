gulp = require 'gulp'
path = require 'path'
gutil = require 'gulp-util'
watchify = require 'watchify'
browserifyBundle = require '../lib/browserify_bundle'

gulp.task 'browserify', (cb) ->

  assetConfig = require path.join(process.cwd(), 'Assetfile')

  devMode = !gutil.env.prod
  bundleQueue = 0

  browserifyEntrypoint = (entrypoint, externals=[]) ->
    browserifyThis src: entrypoint.path, dest: entrypoint.relative,
      prod: !devMode
      beforeBundle: (b) ->
        b.require(entrypoint.path, expose: path.dirname(entrypoint.relative))
        b.external(external) for external in externals

  browserifyExternal = (name, bundleConfig) ->
    browserifyThis src: null, dest: "ext/#{name}/index.js",
      prod: !devMode
      prepend: bundleConfig.prepend
      append: bundleConfig.append
      beforeBundle: (b) ->
        b.require(name) for name in bundleConfig.require or []

  browserifyThis = ({src, dest}, opts={}) ->
    bundleQueue++
  
    initialCbGate = ->
      cb() if --bundleQueue is 0

    opts.browserifyArgs ?= {}
    opts.browserifyArgs[k] = v for k, v of watchify.args if !devMode
  
    dest = "#{path.dirname(path.dirname(dest))}/#{path.basename(path.dirname(dest))}.js" # renames foo/index.coffee -> foo.js
    dest = path.join(assetConfig.dest.dev, 'build/js', dest)                             # set output directory

    b = browserifyBundle {src, dest}, opts
    bundle = ->
      startedAt = Date.now()
      gutil.log "Starting '#{gutil.colors.cyan("browserify #{dest}")}'..."
      b.bundle (err) ->
        duration = Date.now() - startedAt
        if err?
          gutil.log gutil.colors.red('[browserify]', err.message)
        else
          gutil.log "Finished '#{gutil.colors.cyan("browserify #{dest}")}' after #{gutil.colors.magenta("#{duration} ms")}"
        initialCbGate()

    bundle()

    if devMode
      # Wrap with watchify and rebundle on changes
      b = watchify(b)
      b.on 'update', bundle

  # first the externals
  externals = (browserifyExternal(name, config) for name, config of assetConfig.js.externals or {})

  # then all our entrypoints
  gulp.src(assetConfig.js.entrypoints, base: 'src', read: false)
    .on 'data', (entrypoint) -> browserifyEntrypoint entrypoint, externals

  return # don't return the stream above

