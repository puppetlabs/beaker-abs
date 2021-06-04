# beaker-abs

Test commit hooks
Implements a Beaker hypervisor that makes hosts provisioned by the AlwaysBeScheduling service available to a Beaker run.

## Installation

Beaker will automatically load the appropriate hypervisors for any given hosts file, so as long as your project dependencies are satisfied there's nothing else to do. No need to `require` this library in your tests.

As of Beaker 4.0, all hypervisor and DSL extension libraries have been removed and are no longer dependencies. In order to use a specific hypervisor or DSL extension library in your project, you will need to include them alongside Beaker in your Gemfile or project.gemspec. E.g.

~~~ruby
# Gemfile
gem 'beaker', '~>4.0'
gem 'beaker-abs'
# project.gemspec
s.add_runtime_dependency 'beaker', '~>4.0'
s.add_runtime_dependency 'beaker-abs'
~~~

## Usage

Create a beaker host config with `hypervisor: abs`, and pass the data from the
AlwaysBeScheduling service in the `ABS_RESOURCE_HOSTS` environment variable to
the beaker ABS hypervisor. For example, given a host config:

```yaml
---
HOSTS:
  redhat7-64-1:
    hypervisor: abs
    platform: el-7-x86_64
    template: redhat-7-x86_64
    roles:
      - agent
```

Run beaker as:

```
env ABS_RESOURCE_HOSTS=<data> beaker --hosts hosts.yaml
```

Beaker will populate the `vmhostname` property for each host using information provided by the AlwaysBeScheduling service.
This is typically used in a CI scenario, where the jenkins run-me-maybe plugin is populating the ABS_RESOURCE_HOSTS variable.

### Using vmfloaty

If you do not specify a ABS_RESOURCE_HOSTS and request to provision via the beaker options, beaker-abs will fallback to using
your vmfloaty configuration. By default it will look for the service named 'abs'. The name can also be configured via 
the environment variable ABS_SERVICE_NAME or the top level option in the hosts file abs_service_name. Similarly, the priority defaults to "1" which means
it will take precedence over CI tests. Be careful not to run a CI test with this option. The priority can be configured via
the environment variable ABS_SERVICE_PRIORITY or the top level option in the hosts file abs_service_priority.

#### Examples

Changing from default priority 1 to 3 via env var
```
ABS_SERVICE_PRIORITY=3 bundle exec beaker --provision --hosts=hosts.cfg --tests acceptance/tests
```

Changing the service name to look for in ~/.vmfloaty.yml via a beaker option file
```
$ cat options.rb
{
  provision: 'true',
  abs_service_name: "FOOBAR"
}
$ bundle exec beaker --hosts=hosts.cfg --tests acceptance/tests --options options.rb
```

## Development

After checking out the repo, run `bundle install --path .bundle` to install dependencies. Then, run `bundle exec rake test` to run the tests.

To release a new version, run the [release pipeline](https://jenkins-qe.delivery.puppetlabs.net/job/qe_beaker-abs_init-multijob_master/) 
(infrastructure access is required) and provide the following parameters:

- PUBLIC: Whether to release the gem to rubygems.org
- version: Desired version to release

The pipeline will update the version number in `version.rb`, create a git tag for the version, push git commits and tags to
GitHub, and optionally push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/beaker-abs.


## License

The gem is available as open source under the terms of the [Apache-2.0 License](https://opensource.org/licenses/Apache-2.0).

