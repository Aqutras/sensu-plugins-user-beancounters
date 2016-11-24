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

    if File.exist?('/tmp/user_beancounters')
      initial_fail_counts = 0
      initial_beancounters = `cat /tmp/user_beancounters`
      fail_counts = 0
      beancounters = `sudo cat /proc/user_beancounters`
      parse_beancounters(beancounters).each do |items|
        fail_counts += items[5].to_i if config[:counter_name].empty? || config[:counter_name] == items[0]
      end
      parse_beancounters(initial_beancounters).each do |items|
        initial_fail_counts += items[5].to_i if config[:counter_name].empty? || config[:counter_name] == items[0]
      end

      actual_fail_counts = fail_counts - initial_fail_counts
      if actual_fail_counts >= config[:critical]
        critical "#{actual_fail_counts} ; #{actual_fail_counts} failed\n"
      elsif actual_fail_counts >= config[:warn]
        warning "#{actual_fail_counts} ; #{actual_fail_counts} failed\n"
      else
        ok "#{actual_fail_counts} ; #{actual_fail_counts} failed\n"
      end
    else
      beancounters = `sudo cat /proc/user_beancounters`
      File.open('/tmp/user_beancounters', 'w').write(beancounters)
      ok "Initial check"
    end
  end

  private

  def parse_beancounters(str)
    beancounters = []
    lines = str.split(/\n/)
    (2..lines.length).each do |i|
      line = lines[i]
      next unless line
      line.gsub!(/\d*:/, '')
      items = line.chomp.split(/\s+/)
      items.reject!(&:empty?)
      next if items.count <= 0
      beancounters.push(items)
    end
    beancounters
  end
end
