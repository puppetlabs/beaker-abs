require 'beaker'
require 'json'
require 'pry-byebug'

module Beaker
  class Abs < Beaker::Hypervisor
    def initialize(hosts, options)
      @options = options
      @logger = options[:logger]
      @hosts = hosts

      resource_hosts = ENV['ABS_RESOURCE_HOSTS'] || @options[:abs_resource_hosts]

      raise ArgumentError.new("ABS_RESOURCE_HOSTS must be specified when using the Beaker::Abs hypervisor when provisioning") if resource_hosts.nil? && !options[:provision]
      resource_hosts = provision_vms(hosts).to_json if resource_hosts.nil?
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
              # putting ip last as its not set by ABS
              return [:vmhostname, :hostname, :ip]
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

    def provision_vms(hosts)
      ns_request, vm_request = generate_floaty_request_strings(hosts)
      # TODO Implement ns_request

      vm_beaker_abs = []
      # HACKY NEED TO PROPERLY ACCESS VMFLOATY
      # Will return a JSON Object like this:
      # {"redhat-7-x86_64"=>["rich-apparition.delivery.puppetlabs.net", "despondent-side.delivery.puppetlabs.net"], "centos-7-x86_64"=>["firmer-vamp.delivery.puppetlabs.net"]}
      vm_floaty_output = JSON.parse(`floaty --service=abs get #{vm_request} --json`)

      vm_floaty_output.each do |os_platform, value|
        value.each do | hostname |
          vm_beaker_abs.push({"hostname": hostname, "type": os_platform, "engine":"vmpooler"})
        end
      end

      # to do need to figure out what the NSPooler requests are, and combine the output for that with vm_beaker_abs and return that object
      # for now just returning vmpooler abs object
      vm_beaker_abs
    end

    # Based upon the host file, this method generates two strings for what we need to pass to floaty
    # in order to generate nspooler and vmpooler requests
    def generate_floaty_request_strings(hosts)
      # Hopefully clean this up at some point?
      # Use the vmfloaty gem methods directly to determine this?
      # Need to swallow errors if person isn't setup to use nspooler, since most people wont need to
      hacky_ns_list = `floaty list --service=ns`.split
      hacky_vm_list = `floaty list --service=vmpooler`.split
      ns_list = {}
      vm_list = {}
      hosts.each do |host|
        if hacky_vm_list.include?(host[:template])
          if vm_list.include?(host[:template])
            vm_list[host[:template]] = vm_list[host[:template]] + 1
          else
            vm_list[host[:template]] = 1
          end
        elsif hacky_ns_list.include?(host[:template])
          if ns_list.include?(host[:template])
	    ns_list[host[:template]] = ns_list[host[:template]] + 1
          else
            ns_list[host[:template]] = 1
          end
        else
          raise ArgumentError.new("#{host.name} has a template #{host[:template]} that is not found in vmpooler or nspooler")
        end
      end
      vm_request = ""
      ns_request = ""
      vm_list.each do |key, value|
        vm_request.concat("#{key}=#{value} ")
      end
      ns_list.each do |key, value|
	ns_request.concat("#{key}=#{value} ")
      end

      return ns_request, vm_request
    end
  end
end
