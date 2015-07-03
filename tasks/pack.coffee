cp = require 'child_process'
gulp = require 'gulp'

zip = require 'gulp-zip'
appdmg = require 'gulp-appdmg'

winInstaller = require 'electron-windows-installer'

manifest = require '../src/package.json'
secrets = require '../secrets.json'

# Create a dmg for darwin64; only works on OS X because of appdmg
gulp.task 'pack:darwin64', ['sign:darwin64', 'clean:dist:darwin64'], ->
  gulp.src []
    .pipe appdmg
      source: './build/resources/darwin/dmg.json'
      target: './dist/' + manifest.productName + '.dmg'

# Create deb and rpm packages for linux32 and linux64
[32, 64].forEach (arch) ->
  ['deb', 'rpm'].forEach (target) ->
    gulp.task 'pack:linux' + arch + ':' + target, ['build:linux' + arch, 'clean:dist:linux' + arch], ->
      args = [
        '-s dir'
        '-t ' + target
        '--architecture ' + if arch == 32 then 'i386' else 'amd64'
        '--name ' + manifest.name
        '--force' # Overwrite existing packages
        '--after-install ../resources/linux/after-install.sh'
        '--after-remove ../resources/linux/after-remove.sh'
        '--license MIT'
        '--category ' + manifest.section
        '--description "' + manifest.description + '"'
        '--url "' + manifest.homepage + '"'
        '--maintainer "' + manifest.author + '"'
        '--version ' + manifest.version
        '--package ' + './dist/' + manifest.name + '-linux' + arch + '.' + target
        '-C ./build/linux' + arch
        '.'
      ]

      cp.exec 'fpm ' + args.join(' '), done

# Create the win32 installer; only works on Windows
gulp.task 'pack:win32:installer', ['sign:win32', 'clean:dist:win32'], (done) ->
  winInstaller
    appDirectory: './build/win32'
    outputDirectory: './dist'
    loadingGif: './build/resources/win/install-spinner.gif'
    certificateFile: secrets.win.certificateFile,
    certificatePassword: secrets.win.certificatePassword
    setupIcon: './build/resources/win/setup.ico'
    iconUrl: 'https://raw.githubusercontent.com/Aluxian/electron-starter/master/resources/win/app.ico'
    remoteReleases: manifest.repository.url
  .then done, done

# Create the win32 portable zip
gulp.task 'pack:win32:portable', ['sign:win32', 'clean:dist:win32'], (done) ->
  gulp.src './build/win32'
    .pipe zip manifest.name + '-win32-portable.zip'
    .pipe gulp.dest './dist'

# Pack for all the platforms
gulp.task 'pack', [
  'pack:darwin64'
  'pack:linux32'
  'pack:linux64'
  'pack:win32:installer'
  'pack:win32:portable'
]
