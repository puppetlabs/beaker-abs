require 'test_helper'

require 'beaker/hypervisor/abs'

describe 'Beaker::Hypervisor::Abs' do
  let(:logger) do
    create_logger(StringIO.new) # Set to STDOUT for debugging
  end

  let(:global_options) do
    {
      :jenkins_build_url => 'https://jenkins.delivery.puppetlabs.net/job/enterprise_pe-acceptance-tests_integration-system_pe_full-agent-upgrade_nightly_2016.4.x/LAYOUT=centos6-64mcd-debian7-32f-64f,LEGACY_AGENT_VERSION=NONE,PLATFORM=NOTUSED,SCM_BRANCH=2016.4.x,UPGRADE_FROM=2016.1.2,label=beaker-bigjob/13/',
      :department => 'unknown',
      :project => 'enterprise_pe-acceptance-tests_integration-system_pe_full-agent-upgrade_nightly_2016.4.x',
      :created_by => 'Jenkins_coordinator_machine_account'
    }
  end

  before :each do
    ENV['ABS_RESOURCE_HOSTS'] = nil
  end

  def provision_hosts(host_hashes, resource_hosts, options = {})
    hosts = []

    host_hashes.each do |name, host_hash|
      hosts << Beaker::Host.create(name, host_hash, {})
    end

    options = global_options.merge({
      :abs_resource_hosts => JSON.dump(resource_hosts),
      :logger             => logger,
      :pooling_api        => 'http://vmpooler.example.com'
    }).merge(options)

    abs = Beaker::Abs.new(hosts, options)
    abs.provision

    hosts
  end

  describe 'when provisioning' do
    before :each do
      stub_request(:put, %r{http://vmpooler.example.com/vm/.*}).
        to_return(:status => 200, :body => "{ \"ok\": true }", :headers => {})
    end

    it 'sets vmhostname for a single host' do
      host_hash = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'redhat-7-x86_64',
                         'engine'   => 'vmpooler'}]

      hosts = provision_hosts(host_hash, resource_hosts)

      hosts.length.must_equal(1)
      hosts[0]['vmhostname'].must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
    end

    it 'sets vmhostname for multiple hosts of the same type preserving the order' do
      host_hash = {
        'hypervisor' => 'abs',
        'platform'   => 'el-7-x86_64',
        'template'   => 'redhat-7-x86_64',
        'roles'      => [ 'agent' ]
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => host_hash['template'],
                         'engine'   => 'vmpooler'},
                        {'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                         'type'     => host_hash['template'],
                         'engine'   => 'vmpooler'}]

      hosts = provision_hosts({'redhat7-64-1' => host_hash,
                               'redhat7-64-2' => host_hash.dup}, resource_hosts)

      hosts.length.must_equal(2)
      hosts[0]['vmhostname'].must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
      hosts[1]['vmhostname'].must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end

    it 'sets vmhostname for multiple hosts of different types' do
      host_hashes = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        },
        'ubuntu1404-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'ubuntu-14.04-amd64',
          'template'   => 'ubuntu-1404-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'redhat-7-x86_64',
                         'engine'   => 'vmpooler'},
                        {'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                         'type'     => 'ubuntu-1404-x86_64',
                         'engine'   => 'vmpooler'}]

      hosts = provision_hosts(host_hashes, resource_hosts)

      hosts.length.must_equal(2)
      hosts[0]['vmhostname'].must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
      hosts[1]['vmhostname'].must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end

    it 'raises when asked to provision a host not in abs_data' do
      host_hash = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'ubuntu-1404-x86_64',
                         'engine'   => 'vmpooler'}]

      err = assert_raises(ArgumentError) do
        provision_hosts(host_hash, resource_hosts)
      end
      err.message.must_match("Failed to provision host 'redhat7-64-1', no template of type 'redhat-7-x86_64' was provided.")
    end

    it 'raises when the host is missing its template' do
      host_hash = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                                    'type'     => 'redhat-7-x86_64',
                                    'engine'   => 'vmpooler'}]

      err = assert_raises(ArgumentError) do
        provision_hosts(host_hash, resource_hosts)
      end
      err.message.must_match("Failed to provision host 'redhat7-64-1' because its 'template' is missing.")
    end

    it 'prefers abs_data as an ENV variable' do
      host_hash = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      default_resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                                 'type'     => 'ubuntu-1404-x86_64',
                                 'engine'   => 'vmpooler'}]
      overridden_resource_hosts = [{'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                                    'type'     => 'redhat-7-x86_64',
                                    'engine'   => 'vmpooler'}]

      ENV['ABS_RESOURCE_HOSTS'] = JSON.dump(overridden_resource_hosts)
      begin
        hosts = provision_hosts(host_hash, default_resource_hosts)
      ensure
        ENV['ABS_RESOURCE_HOSTS'] = nil
      end

      hosts.length.must_equal(1)
      hosts[0]['vmhostname'].must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end
  end

  def expect_request_with_tag(vm, key, value)
    stub_request(:put, "http://vmpooler.example.com/vm/#{vm}").with do |request|
        json = JSON.parse(request.body)
        assert_includes(json, "tags")
        assert_includes(json["tags"], key)
        assert_equal(json["tags"][key], value)
    end.to_return(:status => 200, :body => "{\"ok\": true}")
  end

  def provision_host(vm, host_tags = nil)
    host_hash = {
      'redhat7-64-1' => {
        'hypervisor' => 'abs',
        'platform'   => 'el-7-x86_64',
        'template'   => 'redhat-7-x86_64',
        'roles'      => [ 'agent', 'master' ]
      }
    }
    host_hash['redhat7-64-1'][:host_tags] = host_tags if host_tags

    resource_host =  [{'hostname' => "#{vm}.delivery.puppetlabs.net",
                       'type'     => 'redhat-7-x86_64',
                       'engine'   => 'vmpooler'}
                     ]

    provision_hosts(host_hash, resource_host)
  end

  describe 'when tagging' do
    it 'includes beaker_version' do
      expect_request_with_tag("m2em9v7895hk7xg", "beaker_version", "3.2.0")

      provision_host("m2em9v7895hk7xg")

      assert_requested(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg")
    end

    it 'includes jenkins_build_url' do
      expect_request_with_tag("m2em9v7895hk7xg", "jenkins_build_url", "https://jenkins.delivery.puppetlabs.net/job/enterprise_pe-acceptance-tests_integration-system_pe_full-agent-upgrade_nightly_2016.4.x/LAYOUT=centos6-64mcd-debian7-32f-64f,LEGACY_AGENT_VERSION=NONE,PLATFORM=NOTUSED,SCM_BRANCH=2016.4.x,UPGRADE_FROM=2016.1.2,label=beaker-bigjob/13/")

      provision_host("m2em9v7895hk7xg")

      assert_requested(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg")
    end

    it 'includes department' do
      expect_request_with_tag("m2em9v7895hk7xg", "department", "unknown")

      provision_host("m2em9v7895hk7xg")

      assert_requested(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg")
    end

    it 'includes created_by' do
      expect_request_with_tag("m2em9v7895hk7xg", "created_by", "Jenkins_coordinator_machine_account")

      provision_host("m2em9v7895hk7xg")

      assert_requested(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg")
    end

    it 'includes vm name' do
      expect_request_with_tag("m2em9v7895hk7xg", "name", "redhat7-64-1")

      provision_host("m2em9v7895hk7xg")

      assert_requested(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg")
    end

    it 'includes roles' do
      expect_request_with_tag("m2em9v7895hk7xg", "roles", "agent, master")

      provision_host("m2em9v7895hk7xg")

      assert_requested(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg")
    end

    it 'includes cinext' do
      expect_request_with_tag("m2em9v7895hk7xg", "cinext", "true")

      provision_host("m2em9v7895hk7xg")

      assert_requested(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg")
    end

    it 'includes host-specific tags' do
      expect_request_with_tag("m2em9v7895hk7xg", "host-specific-tag", "true")

      provision_host("m2em9v7895hk7xg", "host-specific-tag" => "true")

      assert_requested(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg")
    end

    it 'tags all hosts passed to the provision method' do
      stub_request(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg").
        to_return(:status => 200, :body => "{\"ok\": true}")
      stub_request(:put, "http://vmpooler.example.com/vm/eb0zrfuwteq80t7").
        to_return(:status => 200, :body => "{\"ok\": true}")

      host_hashes = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        },
        'ubuntu1404-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'ubuntu-14.04-amd64',
          'template'   => 'ubuntu-1404-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'redhat-7-x86_64',
                         'engine'   => 'vmpooler'},
                        {'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                         'type'     => 'ubuntu-1404-x86_64',
                         'engine'   => 'vmpooler'}]

      provision_hosts(host_hashes, resource_hosts)
    end

    it "only tags hosts that were passed to us, skipping missing hosts" do
      stub_request(:put, "http://vmpooler.example.com/vm/eb0zrfuwteq80t7").
        to_return(:status => 200, :body => "{\"ok\": true}")

      host_hashes = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        },
        'ubuntu1404-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'ubuntu-14.04-amd64',
          'template'   => 'ubuntu-1404-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                         'type'     => 'ubuntu-1404-x86_64',
                         'engine'   => 'vmpooler'}]

      err = assert_raises(ArgumentError) do
        provision_hosts(host_hashes, resource_hosts)
      end
      err.message.must_match(/no template of type 'redhat-7-x86_64' was provided/)

      assert_requested(:put, "http://vmpooler.example.com/vm/eb0zrfuwteq80t7")
    end

    it "raises if we're passed extra hosts we didn't ask for" do
      stub_request(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg").
        to_return(:status => 200, :body => "{\"ok\": true}")
      stub_request(:put, "http://vmpooler.example.com/vm/eb0zrfuwteq80t7").
        to_return(:status => 200, :body => "{\"ok\": true}")

      host_hashes = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        },
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'redhat-7-x86_64',
                         'engine'   => 'vmpooler'},
                        {'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                         'type'     => 'ubuntu-1404-x86_64',
                         'engine'   => 'vmpooler'}]

      err = assert_raises(ArgumentError) do
        provision_hosts(host_hashes, resource_hosts)
      end
      err.message.must_match(/unexpected host 'eb0zrfuwteq80t7.delivery.puppetlabs.net' of type 'ubuntu-1404-x86_64' was provided/)

      assert_requested(:put, "http://vmpooler.example.com/vm/m2em9v7895hk7xg")
    end

    it "connects to the vmpooler host specified by the 'pooling_api' global option" do
      stub_request(:put, "http://myothervmpooler.example.com/vm/m2em9v7895hk7xg").
        to_return(:status => 200, :body => "{\"ok\": true}")

      host_hashes = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'redhat-7-x86_64',
                         'engine'   => 'vmpooler'}]

      provision_hosts(host_hashes, resource_hosts, :pooling_api => 'http://myothervmpooler.example.com')

      assert_requested(:put, "http://myothervmpooler.example.com/vm/m2em9v7895hk7xg")
    end
  end
end
