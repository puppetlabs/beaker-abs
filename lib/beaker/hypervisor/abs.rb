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
        template = host['template']

        raise ArgumentError.new("Failed to provision host '#{host.hostname}' because its 'template' is missing.") if template.nil?

        if provisioned_hosts = type2hosts[template]
          host['vmhostname'] = provisioned_hosts.shift
        else
          raise ArgumentError.new("Failed to provision host '#{host.hostname}', no template of type '#{host['template']}' was provided.")
        end
      end

      # add additional disks to vm

      @hosts.each do |h|
        hostname = h['vmhostname'].split(".")[0]

        if h['disks']
          disks = h['disks']

          disks.each_with_index do |disk_size, index|
            start = Time.
                    add_disk(hostname, disk_size)

            done = wait_for_disk(hostname, disk_size, index)
            if done
              @logger.notify "Spent %.2f seconds adding disk #{index}. " % (Time.now - start)
            else
              raise "Could not verify disk was added after %.2f seconds" % (Time.now - start)
            end
          end
        end
      end
    end

    def cleanup
      # nothing to do
    end
    def add_disk(hostname, disk_size)
      @logger.notify "Requesting an additional disk of size #{disk_size}GB for #{hostname}"

      if !disk_size.to_s.match /[0123456789]/ || size <= '0'
        raise NameError.new "Disk size must be an integer greater than zero!"
      end

      begin
        uri = URI.parse(@options[:pooling_api] + '/api/v1/vm/' + hostname + '/disk/' + disk_size.to_s)

        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri)
        request['X-AUTH-TOKEN'] = @credentials[:vmpooler_token]

        response = http.request(request)

        parsed = parse_response(response)

        raise "Response from #{hostname} indicates disk was not added" if !parsed['ok']

      rescue NameError, RuntimeError, Errno::EINVAL, Errno::ECONNRESET, EOFError,
             Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, *SSH_EXCEPTIONS => e
        report_and_raise(@logger, e, 'Vmpooler.add_disk')
      end
    end

    def parse_response(response)
      parsed_response = JSON.parse(response.body)
    end

    def disk_added?(host, disk_size, index)
      if host['disk'].nil?
        false
      else
        host['disk'][index] == "+#{disk_size}gb"
      end
    end

    def get_vm(hostname)
      begin
        uri = URI.parse(@options[:pooling_api] + '/vm/' + hostname)

        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)

        response = http.request(request)
      rescue RuntimeError, Errno::EINVAL, Errno::ECONNRESET, EOFError,
             Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, *SSH_EXCEPTIONS => e
        @logger.notify "Failed to connect to vmpooler while getting VM information!"
      end
    end

    def wait_for_disk(hostname, disk_size, index)
      response = get_vm(hostname)
      parsed = parse_response(response)

      @logger.notify "Waiting for disk"

      attempts = 0

      while (!disk_added?(parsed[hostname], disk_size, index) && attempts < 20)
        sleep 10
        begin
          response = get_vm(hostname)
          parsed = parse_response(response)
        rescue RuntimeError, Errno::EINVAL, Errno::ECONNRESET, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, *SSH_EXCEPTIONS => e
          report_and_raise(@logger, e, "Vmpooler.wait_for_disk")
        end
        print "."
        attempts += 1
      end

      puts " "

      disk_added?(parsed[hostname], disk_size, index)
    end
  end
end
