var spawn = require('child_process').spawn;
var through = require('through');
var gutil = require('gulp-util');

module.exports = {
  run: function() {
    var proc = spawn('goodeggs-assets', {stdio: ['ignore', 'pipe', 'pipe']});

    var prefixStream = through(function(buf) {
      var line = buf.toString()
        .replace(/^\[\d\d:\d\d:\d\d\]/, '[goodeggs-assets]')
        .replace(/\n$/, '');
      gutil.log(gutil.colors.yellow(line));
    });
    
    proc.stdout.pipe(prefixStream);
    proc.stderr.pipe(prefixStream);
    prefixStream.pipe(process.stdout);
    
    // ensure it gets killed
    process.once('exit', function() { proc.kill() });

    // expose the process handle
    return proc;
  }
}

