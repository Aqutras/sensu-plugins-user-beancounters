#! /usr/bin/env ruby
#  encoding: UTF-8
#
#   user-beancounters-metrics
#
# DESCRIPTION:

#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#

require 'sensu-plugin/metric/cli'
require 'socket'

class UserBeancounters < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: Socket.gethostname.to_s

  def run
    unless File.exist?('/proc/user_beancounters')
      critical 'Not found: /proc/user_beancounters'
    end

    metrics = {}
    timestamp = Time.now.to_i
    beancounters = `sudo cat /proc/user_beancounters`
    columns = %w(held maxheld barrier limit failcnt)
    (2..beancounters.split(/\n/).length).each do |i|
      line = beancounters.split(/\n/)[i]
      next unless line
      line.gsub!(/\d*:/, '')
      items = line.chomp.split(/\s+/)
      items.reject!(&:empty?)
      next if items.count <= 0
      columns.length.times do |j|
        output [config[:scheme], 'user_beancounters', items[0], columns[j]].join('.'), items[j + 1].to_i
      end
    end
    ok
  end
end
