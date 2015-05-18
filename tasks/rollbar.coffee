gulp = require 'gulp'

gulp.task 'rollbar', ->
  path = require 'path'
  gutil = require 'gulp-util'
  request = require 'request'
  through2Concurrent = require 'through2-concurrent'
  urlParse = require('url').parse
  buffer = require 'vinyl-buffer'

  assetConfig = require path.join(process.cwd(), 'Assetfile')
  manifest = require path.join(process.cwd(), assetConfig.dest.manifest)
  concurrency = assetConfig.rollbar.concurrency ? 10

  throw new gutil.PluginError('rollbar', "'rollbar.accessToken' is not set, check your Assetfile.") unless assetConfig.rollbar.accessToken
  throw new gutil.PluginError('rollbar', "'rollbar.version' is not set, check your Assetfile.") unless assetConfig.rollbar.version

  gulp.src('**/*.js.map', cwd: assetConfig.dest.dev)
    .pipe(buffer())
    .pipe through2Concurrent.obj maxConcurrency: concurrency, (file, enc, cb) ->

      source = gutil.replaceExtension(file.relative, '') # .js.map -> .js
      versionedUrl = manifest[source]

      unless versionedUrl?
        gutil.log gutil.colors.red("[WARNING] skipping upload of sourcemap #{file.relative} to Rollbar: #{source} was not in the manifest")
        process.nextTick cb

      unless urlParse(versionedUrl).protocol
        if versionedUrl[0..1] is '//' # protocol-less URL, so add HTTP -- Rollbar ignores it, but it's required.
          versionedUrl = "http:#{versionedUrl}"
        else
          return cb(new gutil.PluginError('rollbar', 'manifest appears to contain paths, but absolute URLs are required.'))

      formData =
        access_token: assetConfig.rollbar.accessToken
        version: assetConfig.rollbar.version
        minified_url: versionedUrl
        source_map:
          value: file.contents
          options:
            filename: file.relative
            contentType: 'application/octet-stream'

      request.post 'https://api.rollbar.com/api/1/sourcemap', {formData, headers: {'Content-Type': 'multipart/form-data'}, json: true}, (err, res) ->
        if err? or res.statusCode isnt 200
          gutil.log gutil.colors.red("[WARNING] failed to upload sourcemap #{file.relative} to Rollbar: #{err?.message or res.body.message or res.body}")
          # but we don't want this to fail the build
        else
          gutil.log gutil.colors.green("uploaded sourcemap #{file.relative} to Rollbar")
        cb()

