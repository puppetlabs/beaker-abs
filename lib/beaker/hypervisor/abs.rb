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

    # Set ssh connection method preference for each host
    #
    # The default order that is already set by beaker ['ip', 'vmhostname', 'hostname']
    # If an engine is using default order provided by beaker, return nothing.
    # If you are changing this, make sure the elements' order is changed
    # and not the elements themselves.
    def get_ssh_connection_preference(engine)
      case engine
      when /^(vmpooler|nspooler)$/
        # putting ip last as its not set by ABS
        return ['vmhostname', 'hostname', 'ip']
      else
        return ['vmhostname', 'hostname', 'ip']
      end
    end

    def provision
      type2hosts = {}

      # resource_host is of the form:
      # [{
      #   "hostname" => "tso2sagbmsauzcw.delivery.puppetlabs.net"
      #   "type"     => "centos-7-i386",
      #   "engine"   => "vmpooler",
      # },
      # {
      #   "hostname" => "sol10-1.delivery.puppetlabs.net"
      #   "type"     => "solaris-10-sparc",
      #   "engine"   => "nspooler",
      # }]
      @resource_hosts.each do |resource_host|
        type = resource_host['type']
        type2hosts[type] ||= []
        type2hosts[type] << resource_host
      end

      # for each host, get a vm for that template type
      @hosts.each do |host|
        template = host['template']

        raise ArgumentError.new("Failed to provision host '#{host.hostname}' because its 'template' is missing.") if template.nil?

        if provisioned_hosts = type2hosts[template]
          host['vmhostname'] = provisioned_hosts[0]['hostname']
          if get_ssh_connection_preference(provisioned_hosts[0]['engine'])
            host[:ssh_connection_preference] = get_ssh_connection_preference(provisioned_hosts[0]['engine'])
          end
          provisioned_hosts.shift
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
