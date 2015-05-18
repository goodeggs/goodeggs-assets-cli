gulp = require 'gulp'

gutil = require 'gulp-util'
path = require 'path'
crypto = require 'crypto'
fs = require 'fs'
rev = require 'gulp-rev'
revReplace = require 'gulp-rev-replace'
_ = require 'lodash'

srcBuilder = (basePath) ->
  [path.join(basePath, '**/*'), "!#{path.join(basePath, '**/*.map')}"] # don't publish sourcemaps

gulp.task 'version', (done) ->
  done = _.once done
  assetConfig = require path.join(process.cwd(), 'Assetfile')

  distribute = _.once (err) ->
    return done(err) if err?

    unless assetConfig.hosts?.length
      gutil.log gutil.colors.red('[WARNING] no asset hosts provided, check your Assetfile')
      return process.nextTick(replace)

    try
      manifest = require(path.resolve(assetConfig.dest.manifest))
      for orig, versioned of manifest
        hex = crypto.createHash('md5').update(versioned).digest('hex').slice(24)
        idx = parseInt(hex, 16) % assetConfig.hosts.length
        host = assetConfig.hosts[idx]
        manifest[orig] = [_.trimRight(host, '/'), _.trimLeft(versioned, '/')].join('/')
      fs.writeFile assetConfig.dest.manifest, JSON.stringify(manifest, null, '  '), 'utf8', replace
    catch err
      replace(err)

  replace = _.once (err) ->
    return done(err) if err?
    gulp.src(srcBuilder(assetConfig.dest.prod))
      .pipe(revReplace(manifest: gulp.src(assetConfig.dest.manifest)))
      .pipe(gulp.dest(assetConfig.dest.prod))
      .on 'error', done
      .on 'end', done

  gulp.src(srcBuilder(assetConfig.dest.dev))
    .pipe(rev())
    .pipe(gulp.dest(assetConfig.dest.prod))
    .pipe(rev.manifest(path.basename(assetConfig.dest.manifest)))
    .pipe(gulp.dest(path.dirname(assetConfig.dest.manifest)))
    .on 'error', distribute
    .on 'end', distribute

  return null # async not stream

