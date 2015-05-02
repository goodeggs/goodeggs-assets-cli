#!/usr/bin/env node
process.title = 'goodeggs-assets';

var path = require('path');
var kexec = require('kexec');
var origCwd = process.cwd();

kexec('gulp', ['--cwd', path.resolve(__dirname, '../tasks'), '--orig-cwd', origCwd].concat(process.argv.slice(2)));

