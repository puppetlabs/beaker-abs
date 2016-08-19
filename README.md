# BeakerAbs

Implements a Beaker hypervisor that makes hosts provisioned by the AlwaysBeScheduling service available to a Beaker run.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'beaker-abs'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install beaker-abs

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

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/beaker-abs.


## License

The gem is available as open source under the terms of the [Apache-2.0 License](https://opensource.org/licenses/Apache-2.0).

