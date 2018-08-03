# beaker-abs

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

