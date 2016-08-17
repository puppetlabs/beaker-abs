require 'beaker'
require 'json'

module Beaker
  class Abs < Beaker::Hypervisor
    def initialize(hosts, options)
      @options = options
      @logger = options[:logger]
      @hosts = hosts

      resource_hosts = ENV['ABS_RESOURCE_HOSTS'] || @options[:abs_resource_hosts]
      raise ArgumentError.new("ABS_RESOURCE_HOSTS must be specified when using the Beaker::Abs hypervisor") if resource_hosts.nil?
      @resource_hosts = JSON.parse(resource_hosts)
    end

    def provision
      type2hosts = {}

      # Each resource_host is of the form:
      # {
      #   "hostname" => "1234567890",
      #   "type"     => "centos-7-i386",
      #   "engine"   => "vmpooler",
      # }
      @resource_hosts.each do |resource_host|
        type = resource_host['type']
        type2hosts[type] ||= []
        type2hosts[type] << resource_host['hostname']
      end

      # for each host, get a vm for that template type
      @hosts.each do |host|
        if provisioned_hosts = type2hosts[host['template']]
          host['vmhostname'] = provisioned_hosts.shift
        else
          raise ArgumentError.new("Failed to provision host '#{host.hostname}', no template of type '#{host['template']}' was provided.")
        end
      end
    end

    def cleanup
      # nothing to do
    end
  end
end
