'use strict'

const TurtleCoind = require('./')
const util = require('util')

var daemon = new TurtleCoind({
  // Load additional daemon parameters here
   dataDir: '/var/lib/turtlecoind', // Where do you store your blockchain?
   loadCheckpoints: '/tmp/checkpoints/checkpoints.csv',
   // pollingInterval: 10000, // How often to check the daemon in milliseconds
   // maxPollingFailures: 5, // How many polling intervals can fail before we emit a down event?
})

function log (message) {
  console.log(util.format('%s: %s', (new Date()).toUTCString(), message))
}

daemon.on('start', (args) => {
  log(util.format('TurtleCoind has started... %s', args))
})

daemon.on('started', () => {
  log('TurtleCoind is attempting to synchronize with the network...')
})

daemon.on('syncing', (info) => {
  log(util.format('TurtleCoind has syncronized %s out of %s blocks [%s%]', info.height, info.network_height, info.percent))
})

daemon.on('synced', () => {
  log('TurtleCoind is synchronized with the network...')
})

daemon.on('ready', (info) => {
  log(util.format('TurtleCoind is waiting for connections at %s @ %s - %s H/s', info.height, info.difficulty, info.globalHashRate))
})

daemon.on('desync', (daemon, network, deviance) => {
  log(util.format('TurtleCoind is currently off the blockchain by %s blocks. Network: %s  Daemon: %s', deviance, network, daemon))
})

daemon.on('down', () => {
  log('TurtleCoind is not responding... stopping process...')
  daemon.stop()
})

daemon.on('stopped', (exitcode) => {
  log(util.format('TurtleCoind has closed (exitcode: %s)... restarting process...', exitcode))
  daemon.start()
})

daemon.on('info', (info) => {
  log(info)
})

daemon.on('error', (err) => {
  log(err)
})

daemon.start()
