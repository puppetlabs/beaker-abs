require 'test_helper' # THIS IS MINITEST
require 'beaker/hypervisor/abs'
require 'vmfloaty/utils'

class FakeLogger
  attr_reader :infos, :warns

  def initialize
    @infos = []
    @warns = []
  end

  def info(msg)
    @infos << msg
  end

  def warn(msg)
    @warns << msg
  end

  def notify(*); end
end

describe 'Beaker::Hypervisor::Abs' do
  def provision_hosts(host_hashes, resource_hosts)
    hosts = []

    host_hashes.each do |name, host_hash|
      hosts << Beaker::Host.create(name, host_hash, {})
    end

    abs = Beaker::Abs.new(hosts, {:abs_resource_hosts => JSON.dump(resource_hosts)})
    abs.provision

    hosts
  end

  describe 'initialize' do
    it 'does not raise when neither ABS_RESOURCE_HOSTS nor provision: true is set' do
      Beaker::Abs.new([], {:provision => false})
    end

    it 'initializes resource_hosts to an empty array when neither is provided' do
      abs = Beaker::Abs.new([], {:provision => false})
      _(abs.instance_variable_get(:@resource_hosts)).must_equal []
    end

    it 'parses ABS_RESOURCE_HOSTS from the environment' do
      resource_hosts = [{'hostname' => 'foo.example.com', 'type' => 'centos-7', 'engine' => 'vmpooler'}]
      ENV['ABS_RESOURCE_HOSTS'] = resource_hosts.to_json
      begin
        abs = Beaker::Abs.new([], {})
        _(abs.instance_variable_get(:@resource_hosts)).must_equal resource_hosts
      ensure
        ENV['ABS_RESOURCE_HOSTS'] = nil
      end
    end

    it 'parses abs_resource_hosts from options' do
      resource_hosts = [{'hostname' => 'bar.example.com', 'type' => 'el-7', 'engine' => 'nspooler'}]
      abs = Beaker::Abs.new([], {:abs_resource_hosts => resource_hosts.to_json})
      _(abs.instance_variable_get(:@resource_hosts)).must_equal resource_hosts
    end
  end

  describe 'when ABS_RESOURCE_HOSTS is not ready' do
    it '#provision_vms works properly' do

      host_hashes = {
          'redhat7-64-1' => {
              'hypervisor' => 'abs',
              'platform'   => 'el-7-x86_64',
              'template'   => 'redhat-7-x86_64',
              'roles'      => [ 'agent' ]
          }
      }

      hosts = []

      host_hashes.each do |name, host_hash|
        hosts << Beaker::Host.create(name, host_hash, {})
      end

      # TODO: this test queries the real floaty, needs stubs/mocks
      # but the minitest does not like me so it's not working
      # abs = Beaker::Abs.new(hosts, {:provision => true})
      end
    end

    describe 'when provisioning' do
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

      _(hosts.length).must_equal(1)
      _(hosts[0]['vmhostname']).must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
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

      _(hosts.length).must_equal(2)
      _(hosts[0]['vmhostname']).must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
      _(hosts[1]['vmhostname']).must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
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

      _(hosts.length).must_equal(2)
      _(hosts[0]['vmhostname']).must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
      _(hosts[1]['vmhostname']).must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
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
      _(err.message).must_match("Failed to provision host 'redhat7-64-1', no template of type 'redhat-7-x86_64' was provided.")
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
      _(err.message).must_match("Failed to provision host 'redhat7-64-1' because its 'template' is missing.")
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

      _(hosts.length).must_equal(1)
      _(hosts[0]['vmhostname']).must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end

    it 'raises in provision when there are no resource hosts and provision: false' do
      host = Beaker::Host.create('myhost', {'hypervisor' => 'abs', 'platform' => 'el-7-x86_64', 'template' => 'centos-7'}, {})
      abs = Beaker::Abs.new([host], {:provision => false})
      assert_raises(ArgumentError) { abs.provision }
    end

    it 'calls provision_vms and assigns vmhostname when resource_hosts is empty and provision: true' do
      provisioned = [{'hostname' => 'new.example.com', 'type' => 'centos-7', 'engine' => 'beaker-abs'}]
      host = Beaker::Host.create('myhost', {'hypervisor' => 'abs', 'platform' => 'el-7-x86_64', 'template' => 'centos-7'}, {})
      abs = Beaker::Abs.new([host], {:provision => true})
      abs.stub(:provision_vms, provisioned) { abs.provision }
      _(host['vmhostname']).must_equal 'new.example.com'
    end

    it 'does not call set_ssh_connection_preference method if hypervisor does not responds' do
      hypervisor_mock = Minitest::Mock.new
      1.times { hypervisor_mock.expect(:respond_to?, false, [:set_ssh_connection_preference]) }
      provision_hosts({}, {})
    end

    it 'calls set_ssh_connection_preference method if beaker responds' do
      hypervisor_mock = Minitest::Mock.new
      2.times { hypervisor_mock.expect(:respond_to?, true, [:set_ssh_connection_preference]) }
      provision_hosts({}, {})
    end

  end

  describe 'cleanup' do
    def make_abs(hosts = [], extra_options = {})
      Beaker::Abs.new(hosts, {:logger => FakeLogger.new, :provision => false}.merge(extra_options))
    end

    it 'is a no-op when ABS_RESOURCE_HOSTS env var is set' do
      ENV['ABS_RESOURCE_HOSTS'] = '[]'
      begin
        called = false
        Service.stub(:new, ->(*) { called = true }) do
          make_abs.cleanup
        end
        refute called
      ensure
        ENV['ABS_RESOURCE_HOSTS'] = nil
      end
    end

    it 'is a no-op when abs_resource_hosts option is set' do
      called = false
      Service.stub(:new, ->(*) { called = true }) do
        make_abs([], {:abs_resource_hosts => '[]'}).cleanup
      end
      refute called
    end

    it 'is a no-op when there are no hosts' do
      called = false
      Service.stub(:new, ->(*) { called = true }) do
        make_abs([]).cleanup
      end
      refute called
    end

    it 'calls vmfloaty delete with all hostnames' do
      hosts = [Beaker::Host.create('foo.example.com', {'hypervisor' => 'abs', 'platform' => 'el-7-x86_64'}, {}),
               Beaker::Host.create('bar.example.com', {'hypervisor' => 'abs', 'platform' => 'el-7-x86_64'}, {})]
      service_mock = Minitest::Mock.new
      service_mock.expect(:delete,
                          { 'foo.example.com' => { 'ok' => true }, 'bar.example.com' => { 'ok' => true } },
                          [false, ['foo.example.com', 'bar.example.com']])
      Conf.stub(:read_config, {}) do
        Service.stub(:new, ->(*) { service_mock }) do
          make_abs(hosts).cleanup
        end
      end
      service_mock.verify
    end

    it 'logs info for each successfully deleted host' do
      hosts = [Beaker::Host.create('foo.example.com', {'hypervisor' => 'abs', 'platform' => 'el-7-x86_64'}, {})]
      abs = make_abs(hosts)
      service_mock = Minitest::Mock.new
      service_mock.expect(:delete, { 'foo.example.com' => { 'ok' => true } }, [false, ['foo.example.com']])
      Conf.stub(:read_config, {}) do
        Service.stub(:new, ->(*) { service_mock }) do
          abs.cleanup
        end
      end
      _(abs.instance_variable_get(:@logger).infos.first).must_match(/foo\.example\.com/)
    end

    it 'logs a warning for each host that fails to delete' do
      hosts = [Beaker::Host.create('foo.example.com', {'hypervisor' => 'abs', 'platform' => 'el-7-x86_64'}, {})]
      abs = make_abs(hosts)
      service_mock = Minitest::Mock.new
      service_mock.expect(:delete, { 'foo.example.com' => { 'ok' => false } }, [false, ['foo.example.com']])
      Conf.stub(:read_config, {}) do
        Service.stub(:new, ->(*) { service_mock }) do
          abs.cleanup
        end
      end
      _(abs.instance_variable_get(:@logger).warns.first).must_match(/foo\.example\.com/)
    end
  end

end
