# By doing a "require 'net/ping'" you are requiring every subclass.  If you
# want to require a specific ping type only, do "require 'net/ping/tcp'",
# for example.
#
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'ping/tcp'
require 'ping/udp'
require 'ping/icmp'
require 'ping/external'
require 'ping/http'
