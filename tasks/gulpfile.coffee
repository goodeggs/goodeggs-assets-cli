gutil = require 'gulp-util'

# load our tasks
require './index'

# change back to the app's directory
process.chdir gutil.env['orig-cwd']

