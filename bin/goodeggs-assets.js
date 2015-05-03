#!/usr/bin/env node
process.title = 'goodeggs-assets';

var path = require('path');
var kexec = require('kexec');
var gulpPath = path.join(path.dirname(require.resolve('gulp')), 'bin/gulp.js');

kexec(gulpPath, ['--gulpfile', path.resolve(__dirname, '../tasks/gulpfile.coffee'), '--cwd', process.cwd()].concat(process.argv.slice(2)));

