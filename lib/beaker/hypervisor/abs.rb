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

    def connection_preference(host)
      vmhostname = host[:vmhostname]
      if vmhostname && host[:hypervisor] == 'abs'
        @resource_hosts.each do |resource_host|
          if resource_host['hostname'] == vmhostname
            engine = resource_host['engine']
            case engine
            when /^(vmpooler|nspooler)$/
              # ABS does not set ip, do not include
              # vmpooler hostname is the platform name, nspooler hostname == vmhostname
              return [:vmhostname]
            else
              super
            end
          end
        end
      end
      super
    end

    def provision
      type2hosts = {}

      # Each resource_host is of the form:
      # {
      #   "hostname" => "mkbx0m6dnnntgz1.delivery.puppetlabs.net",
      #   "type"     => "centos-7-i386",
      #   "engine"   => "vmpooler",
      # }
      # {
      #   "hostname" => "sol10-1.delivery.puppetlabs.net",
      #   "type"     => "solaris-10-sparc",
      #   "engine"   => "nspooler",
      # }
      @resource_hosts.each do |resource_host|
        type = resource_host['type']
        type2hosts[type] ||= []
        type2hosts[type] << resource_host['hostname']
        type2hosts[type] << resource_host['ip']
      end

      # for each host, get a vm for that template type
      @hosts.each do |host|
        template = host['template']

        raise ArgumentError.new("Failed to provision host '#{host.hostname}' because its 'template' is missing.") if template.nil?

        if provisioned_hosts = type2hosts[template]
          host['vmhostname'] = provisioned_hosts.shift
          host['ip'] = provisioned_hosts.shift
        else
          raise ArgumentError.new("Failed to provision host '#{host.hostname}', no template of type '#{host['template']}' was provided.")
        end
      end
      if Beaker::Hypervisor.respond_to?(:set_ssh_connection_preference)
        Beaker::Hypervisor.set_ssh_connection_preference(@hosts, self)
      end
    end

    def cleanup
      # nothing to do
    end
  end
end
