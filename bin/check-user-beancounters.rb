#! /usr/bin/env ruby
#  encoding: UTF-8
#
#   user-beancounters-metrics
#
# DESCRIPTION:

#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   check-user-beancounters.rb -b counter_name -w warn_fail_count -c critical_fail_count
#

require 'sensu-plugin/metric/cli'
require 'socket'

class UserBeancounters < Sensu::Plugin::Metric::CLI::Graphite
  option :warn,
         short: '-w WARNING',
         long: '--warning',
         proc: proc(&:to_i),
         default: 1

  option :critical,
         short: '-c CRITICAL',
         long: '--critical',
         proc: proc(&:to_i),
         default: 10

  option :counter_name,
         short: '-b COUNTER_NAME',
         long: '--beancounter_name',
         proc: proc(&:to_s),
         default: ''

  def run
    unless File.exist?('/proc/user_beancounters')
      critical 'Not found: /proc/user_beancounters'
    end

    fail_counts = 0
    timestamp = Time.now.to_i
    beancounters = `sudo cat /proc/user_beancounters`
    (2..beancounters.split(/\n/).length).each do |i|
      line = beancounters.split(/\n/)[i]
      next unless line
      line.gsub!(/\d*:/, '')
      items = line.chomp.split(/\s+/)
      items.reject!(&:empty?)
      next if items.count <= 0
      fail_counts += items[5].to_i if config[:counter_name].empty? || config[:counter_name] == items[0]
    end

    if fail_counts >= config[:critical]
      critical "#{fail_counts} ; #{fail_counts} failed\n"
    elsif fail_counts >= config[:warn]
      warning "#{fail_counts} ; #{fail_counts} failed\n"
    else
      ok "#{fail_counts} ; #{fail_counts} failed\n"
    end
  end
end
