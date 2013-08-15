require "logger"

$log = Logger.new(STDOUT)

# change $log.level to Logger::DEBUG, etc. as you need
$log.level=Logger::INFO

# change $debug to true to see all the debug logs
# NB: note this slows down everything if $debug is true even if the log level is not DEBUG
$debug = false 
