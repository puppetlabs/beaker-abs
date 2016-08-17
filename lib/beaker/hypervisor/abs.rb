require 'beaker'
require 'json'

module Beaker
  class Abs < Beaker::Hypervisor
    def initialize(hosts, options)
      @options = options
      @logger = options[:logger]
      @hosts = hosts

      data = ENV['ABS_DATA'] || @options[:abs_data]
      raise ArgumentError.new("ABS_DATA must be specified when using the Beaker::Abs hypervisor") if data.nil?
      @abs_data = JSON.parse(data)
    end

    def provision
      type2hostname = {}

      @abs_data.each do |host_info|
        type = host_info['type']
        type2hostname[type] ||= []
        type2hostname[type] << host_info['hostname']
      end

      # for each host, lookup its vmhostname from abs-data
      @hosts.each do |host|
        if hosts = type2hostname[host['template']]
          host['vmhostname'] = hosts.shift
        else
          raise ArgumentError.new("Unable to provision host with template '#{host['template']}'")
        end
      end
    end

    def cleanup
      # nothing to do
    end
  end
end
