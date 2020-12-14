require 'beaker'
require 'json'
require 'pry-byebug'
require 'vmfloaty'
require 'vmfloaty/conf'
require 'vmfloaty/utils'

module Beaker
  class Clifloaty
    # the floaty service needs a 'cli' object that would normally represent the flags passed on the command line
    # that object is then "merged" with the floaty config files to add/change options
    # creating a dummy cli here
    attr_reader :url, :token, :user, :service, :priority
    def initialize(service, priority)
      @service = service #the name of the service you want to use
      @priority = priority
    end
  end
  
  class Abs < Beaker::Hypervisor
    def initialize(hosts, options)
      @options = options
      @logger = options[:logger]
      @hosts = hosts

      resource_hosts = ENV['ABS_RESOURCE_HOSTS'] || @options[:abs_resource_hosts]

      @abs_service_name = ENV['ABS_SERVICE_NAME'] || @options[:abs_service_name] || "abs"
      @abs_service_priority = ENV['ABS_SERVICE_PRIORITY'] || @options[:abs_service_priority] || "1"

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

    def provision_vms(hosts)

      verbose = false
      config = Conf.read_config # get the vmfloaty config file in home dir

      # TODO: the options object provided by the floaty cli is required in get_service_config()
      cli = Clifloaty.new(@abs_service_name, @abs_service_priority)

      #the service object is the interfacte to all methods
      abs_service = Service.new(cli, config)
      supported_vm_list = abs_service.list(verbose)
      supported_vm_list = supported_vm_list.reject { |e| e.empty? }
      supported_vm_list = supported_vm_list.reject { |e| e.start_with?("*") }

      vm_request = generate_floaty_request_strings(hosts, supported_vm_list)


      vm_beaker_abs = []
      # Will return a JSON Object like this:
      # {"redhat-7-x86_64"=>["rich-apparition.delivery.puppetlabs.net", "despondent-side.delivery.puppetlabs.net"], "centos-7-x86_64"=>["firmer-vamp.delivery.puppetlabs.net"]}
      os_types = Utils.generate_os_hash(vm_request.split)
      vm_floaty_output = abs_service.retrieve(verbose, os_types)


      raise ArgumentError.new("Timed out getting the ABS resources") if vm_floaty_output.nil?
      vm_floaty_output_cleaned = Utils.standardize_hostnames(vm_floaty_output)
      vm_floaty_output_cleaned.each do |os_platform, value|
        # filter any extra key that does not have an Array value
        if !value.is_a?(Array)
          next
        end
        value.each do | hostname |
          # I don't think the engine is being used by the beaker-abs process
          vm_beaker_abs.push({"hostname": hostname, "type": os_platform, "engine":"beaker-abs"})
        end
      end

      # to do need to figure out what the NSPooler requests are, and combine the output for that with vm_beaker_abs and return that object
      # for now just returning vmpooler abs object
      vm_beaker_abs
    end

    # Based upon the host file, this method counts the number of each template needed
    # and generates the host=Xnum eg redhat-7-x86_64=2 expected by floaty
    def generate_floaty_request_strings(hosts, supported_vm_list)
      vm_list = {}

      hosts.each do |host|
        if supported_vm_list.include?(host[:template])
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

      vm_request
    end
  end
end
