require 'test_helper'
require 'beaker/hypervisor/abs'

describe 'Beaker::Hypervisor::Abs' do
  describe 'when provisioning' do
    it 'sets vmhostname for a single host' do
      host_hash = {
        'hypervisor' => 'abs',
        'platform'   => 'el-7-x86_64',
        'template'   => 'redhat-7-x86_64',
        'roles'      => [ 'agent' ]
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => host_hash['template'],
                         'engine'   => 'vmpooler'}]

      host = Beaker::Host.create('redhat7-64-1', host_hash, {})
      abs = Beaker::Abs.new([host], {:abs_resource_hosts => JSON.dump(resource_hosts)})
      abs.provision

      host['vmhostname'].must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
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

      host1 = Beaker::Host.create('redhat7-64-1', host_hash, {})
      host2 = Beaker::Host.create('redhat7-64-2', host_hash, {})
      abs = Beaker::Abs.new([host1, host2], {:abs_resource_hosts => JSON.dump(resource_hosts)})
      abs.provision

      host1['vmhostname'].must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
      host2['vmhostname'].must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end

    it 'sets vmhostname for multiple hosts of different types' do
      redhat_host_hash = {
        'hypervisor' => 'abs',
        'platform'   => 'el-7-x86_64',
        'template'   => 'redhat-7-x86_64',
        'roles'      => [ 'agent' ]
      }
      ubuntu_host_hash = {
        'hypervisor' => 'abs',
        'platform'   => 'ubuntu-14.04-amd64',
        'template'   => 'ubuntu-1404-x86_64',
        'roles'      => [ 'agent' ]
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => redhat_host_hash['template'],
                         'engine'   => 'vmpooler'},
                        {'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                         'type'     => ubuntu_host_hash['template'],
                         'engine'   => 'vmpooler'}]

      host1 = Beaker::Host.create('redhat7-64-1', redhat_host_hash, {})
      host2 = Beaker::Host.create('ubuntu1404-64-1', ubuntu_host_hash, {})
      abs = Beaker::Abs.new([host1, host2], {:abs_resource_hosts => JSON.dump(resource_hosts)})
      abs.provision

      host1['vmhostname'].must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
      host2['vmhostname'].must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end

    it 'raises when asked to provision a host not in abs_data' do
      host_hash = {
        'hypervisor' => 'abs',
        'platform'   => 'el-7-x86_64',
        'template'   => 'redhat-7-x86_64',
        'roles'      => [ 'agent' ]
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'ubuntu-1404-x86_64',
                         'engine'   => 'vmpooler'}]

      host = Beaker::Host.create('redhat7-64-1', host_hash, {})
      abs = Beaker::Abs.new([host], {:abs_resource_hosts => JSON.dump(resource_hosts)})

      err = assert_raises(ArgumentError) do
        abs.provision
      end
      err.message.must_match("Failed to provision host 'redhat7-64-1', no template of type 'redhat-7-x86_64' was provided.")
    end

    it 'prefers abs_data as an ENV variable' do
      host_hash = {
        'hypervisor' => 'abs',
        'platform'   => 'el-7-x86_64',
        'template'   => 'redhat-7-x86_64',
        'roles'      => [ 'agent' ]
      }
      default_resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                                 'type'     => 'ubuntu-1404-x86_64',
                                 'engine'   => 'vmpooler'}]
      overridden_resource_hosts = [{'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                                    'type'     => 'redhat-7-x86_64',
                                    'engine'   => 'vmpooler'}]

      ENV['ABS_RESOURCE_HOSTS'] = JSON.dump(overridden_resource_hosts)
      begin
        host = Beaker::Host.create('redhat7-64-1', host_hash, {})
        abs = Beaker::Abs.new([host], {:abs_resource_hosts => JSON.dump(default_resource_hosts)})
        abs.provision
      ensure
        ENV['ABS_RESOURCE_HOSTS'] = nil
      end

      host['vmhostname'].must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end
  end
end
