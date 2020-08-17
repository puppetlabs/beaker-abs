require 'beaker'
require 'json'

module Beaker
  FLOATY_BIN = `bundle info vmfloaty --path`.chomp.concat('/bin/floaty')

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
      vm_request = generate_floaty_request_strings(hosts)

      vm_beaker_abs = []
      # HACKY NEED TO PROPERLY ACCESS VMFLOATY
      # Will return a JSON Object like this:
      # {"redhat-7-x86_64"=>["rich-apparition.delivery.puppetlabs.net", "despondent-side.delivery.puppetlabs.net"], "centos-7-x86_64"=>["firmer-vamp.delivery.puppetlabs.net"]}
      vm_floaty_output = JSON.parse(`#{FLOATY_BIN} --service=abs get #{vm_request} --json`)

      vm_floaty_output.each do |os_platform, value|
        value.each do | hostname |
          vm_beaker_abs.push({"hostname": hostname, "type": os_platform, "engine":"vmpooler"})
        end
      end

      vm_beaker_abs
    end

    # Based upon the host file, this method generates a string for what we need to pass to floaty
    # in order to generate a get request
    def generate_floaty_request_strings(hosts)
      list_of_possible_vms = `#{FLOATY_BIN} list --service=abs`.split
      vm_list = {}
      hosts.each do |host|
        if list_of_possible_vms.include?(host[:template])
          if vm_list.include?(host[:template])
            vm_list[host[:template]] = vm_list[host[:template]] + 1
          else
            vm_list[host[:template]] = 1
          end
        else
          raise ArgumentError.new("#{host.name} has a template #{host[:template]} that is not found in vmpooler or nspooler")
        end
      end
      vm_request = ""
      vm_list.each do |key, value|
        vm_request.concat("#{key}=#{value} ")
      end

      return vm_request
    end
  end
end
