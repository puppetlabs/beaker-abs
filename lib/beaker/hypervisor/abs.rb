require 'beaker'
require 'beaker/version'
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
      type2hosts = @resource_hosts.group_by { |resource_host| resource_host['type'] }

      missing_templates = []
      missing_hosts = []

      # for each host, get a vm for that template type
      @hosts.each do |host|
        template = host['template']

        if template.nil?
          missing_templates << host
          next
        end

        if provisioned_hosts = type2hosts[template]
          resource_host = provisioned_hosts.shift
          host['vmhostname'] = resource_host['hostname']
          if resource_host['engine'] == 'vmpooler'
            tag(host)
          end
        else
          missing_hosts << host
        end
      end

      if host = missing_templates.first
        raise ArgumentError.new("Failed to provision host '#{host.hostname}' because its 'template' is missing.")
      end

      if host = missing_hosts.first
        raise ArgumentError.new("Failed to provision host '#{host.hostname}', no template of type '#{host['template']}' was provided.")
      end

      type2hosts.each_pair do |_, resource_hosts|
        if host = resource_hosts.first
          raise ArgumentError.new("unexpected host '#{host['hostname']}' of type '#{host['type']}' was provided")
        end
      end
    end

    def cleanup
      # nothing to do
    end

    private

    def tag(h)
      begin
        uri = URI.parse(@options[:pooling_api] + '/vm/' + h['vmhostname'].split('.')[0])

        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Put.new(uri.request_uri)

        # merge pre-defined tags with host tags
        request.body = { 'tags' => add_tags(h) }.to_json

        response = http.request(request)
        parsed_response = JSON.parse(response.body)

        unless parsed_response['ok']
          @logger.notify "Failed to tag host '#{h['vmhostname']}'!"
        end
      rescue JSON::ParserError => e
        @logger.notify "Failed to tag host '#{h['vmhostname']}'! (failed with #{e.class})"
      rescue => e
        @logger.notify "Failed to connect to vmpooler for tagging!: #{e.inspect}"
      end
    end

    def add_tags(host)
      # All of these tags except for 'cinext' are copied from
      # beaker's vmpooler hypervisor.
      (host[:host_tags] || {}).merge(
        'beaker_version'    => Beaker::Version::STRING,
        'jenkins_build_url' => @options[:jenkins_build_url],
        'department'        => @options[:department],
        'project'           => @options[:project],
        'created_by'        => @options[:created_by],
        'name'              => host.name,
        'roles'             => host.host_hash[:roles].join(', '),
        'cinext'            => 'true'
      )
    end
  end
end
