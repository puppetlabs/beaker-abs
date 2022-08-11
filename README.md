# beaker-abs

[![Gem Version](https://badge.fury.io/rb/beaker-abs.svg)](https://badge.fury.io/rb/beaker-abs)
[![Testing](https://github.com/puppetlabs/beaker-abs/actions/workflows/testing.yml/badge.svg)](https://github.com/puppetlabs/beaker-abs/actions/workflows/testing.yml)

- [Description](#description)
- [Installation](#installation)
- [Usage](#usage)
  - [Using vmfloaty](#using-vmfloaty)
    - [Examples](#examples)
- [Environment vars](#environment-vars)
- [Releasing](#releasing)
- [Contributing](#contributing)
- [License](#license)

## Description

Implements a Beaker hypervisor that makes hosts provisioned by the AlwaysBeScheduling service available to a Beaker run.

## Installation

Beaker will automatically load the appropriate hypervisors for any given hosts file, so as long as your project dependencies are satisfied there's nothing else to do. No need to `require` this library in your tests.

As of Beaker 4.0, all hypervisor and DSL extension libraries have been removed and are no longer dependencies. In order to use a specific hypervisor or DSL extension library in your project, you will need to include them alongside Beaker in your Gemfile or project.gemspec. E.g.

```ruby
# Gemfile
gem 'beaker', '~>4.0'
gem 'beaker-abs'
# project.gemspec
s.add_runtime_dependency 'beaker', '~>4.0'
s.add_runtime_dependency 'beaker-abs'
```

Beaker-abs changes the default beaker (core) behavior of settings the NET::SSH ssh config to 'false' which means do not respect any of the client's ssh_config.
If beaker-abs detects that the ssh config will be false (it was not replaced in the option files, in the HOST config etc) it sets it to the value of
SSH_CONFIG_FILE or default to 'true'. True means it will automatically check the typical locations (~/.ssh/config, /etc/ssh_config). Respecting the ssh_config is
useful to specify things like no strict hostkley checking, and also to support the smallstep 'step' command in CI.

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

```bash
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

```bash
ABS_SERVICE_PRIORITY=3 bundle exec beaker --provision --hosts=hosts.cfg --tests acceptance/tests
```

Changing the service name to look for in ~/.vmfloaty.yml via a beaker option file

```bash
$ cat options.rb
{
  provision: 'true',
  abs_service_name: "FOOBAR"
}
$ bundle exec beaker --hosts=hosts.cfg --tests acceptance/tests --options options.rb
```

## Environment vars

| Var      | Description | Default |
| ----------- | ----------- | ------ |
| ABS_SERVICE_NAME      | When using locally via vmfloaty, the --service to use       | abs |
| ABS_SERVICE_PRIORITY  | When using locally via vmfloaty, the priority to use        | 1 |
| SSH_CONFIG_FILE       | If beaker-abs detects the beaker default of 'false', you can specify a file location for the ssh_config. True means it will automatically check the typical locations (~/.ssh/config, /etc/ssh_config). | true |

## Releasing

Open a release prep PR and run the release action:

1. Bump the "version" parameter in `lib/beaker-abs/version.rb` appropriately based merged pull requests since the last release.
2. Update the changelog by running `docker run -it --rm -e CHANGELOG_GITHUB_TOKEN -v $(pwd):/usr/local/src/your-app githubchangeloggenerator/github-changelog-generator:1.16.2 github_changelog_generator --future-release <INSERT_NEXT_VERSION>`
3. Commit and push changes to a new branch, then open a pull request against `main` and be sure to add the "maintenance" label.
4. After the pull request is approved and merged, then navigate to Actions --> Release Action --> run workflow --> Branch: main --> Run workflow.

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/puppetlabs/beaker-abs>.

## License

The gem is available as open source under the terms of the [Apache-2.0 License](https://opensource.org/licenses/Apache-2.0).
