gulp                    = require 'gulp'
gutil                   = require 'gulp-util'
clean                   = require 'gulp-clean'
coffeeReactTransform    = require 'gulp-coffee-react-transform'
coffeelint              = require 'gulp-coffeelint'
coffee                  = require 'gulp-coffee'
ignore                  = require 'gulp-ignore'
_                       = require 'highland'
monitorCtrlC            = require 'monitorctrlc'
path                    = require 'path'
{spawn, execSync}       = require 'child_process'
{colors, log}           = gutil

config =
    clean:
        index: 'index.ios.js'
        dist: './dist/**/*'
    watchers:
        index: '*.coffee'
        files: 'src/**/*.{coffee,cjsx}'

    index: src: 'index.ios.coffee', dist: './'
    dist: src: 'src/**/*.{coffee,cjsx}', dist: './dist'

printCoffeeError = (err) ->
    if typeof err is 'object'
        log colors.white.bgRed('ERRORS:'), err.message if err.message
        process.stdout.write colors.green('filename:') + ' ' + err.filename + '\n' if err.filename
        process.stdout.write colors.green('stack:   ') + ' ' + err.stack + '\n' if err.stack
        process.stdout.write colors.green('plugin:  ') + ' ' + err.plugin + '\n' if err.plugin
    else
        log err
    @emit 'end'

pkill = (pid) ->
    execSync 'pkill -P ' + pid

cleanFiles = (targetPath) ->
    gulp.src targetPath, read: false
        .pipe clean force: true

lintAndCompile = (src, dest) ->
    lint = coffeelint './coffeelint.json'
        .pipe coffeelint.reporter()

    coffeeCompile = coffee(bare: true)
        .pipe gulp.dest dest

    transformed = gulp.src src
        .pipe coffeeReactTransform()
        .pipe _()

    # lint
    transformed.fork().pipe coffeelint './coffeelint.json'
        .pipe coffeelint.reporter()

    # compile coffee sources
    compile = transformed.fork().pipe coffee bare: true
        .on 'error', printCoffeeError
        .pipe gulp.dest dest

startPackageServer = ->
    # Easier to just shell out to the packager than use the JS API.
    cmd = './node_modules/react-native/packager/packager.sh'
    args = [
      '--projectRoots'
      path.resolve process.cwd(), 'node_modules/react-native'
      '--root'
      process.cwd()
      '--port'
      8081
      # you may add your assetRoots here
    ]
    opts = stdio: 'inherit'
    spawn cmd, args, opts

gulp.task 'cleanDist', ->
    cleanFiles config.clean.dist

gulp.task 'cleanIndex', ->
    cleanFiles config.clean.index

gulp.task 'index', ->
    lintAndCompile config.index.src, config.index.dist

gulp.task 'dist', ->
    lintAndCompile config.dist.src, config.dist.dist

gulp.task 'build', ['cleanDist', 'cleanIndex'], ->
    gulp.start 'dist', 'index'

gulp.task 'watch', ->
    packageServer = null

    monitorCtrlC ->
        log "'#{colors.cyan('^C')}', exiting"
        if packageServer
            pkill packageServer.pid
            packageServer = null
        process.exit()

    packageServer = startPackageServer()
    gulp.watch [config.watchers.index], ['index']
    gulp.watch [config.watchers.files], ['dist']

gulp.task 'default', ['watch']
