source 'https://rubygems.org'

# Specify your gem's dependencies in beaker-abs.gemspec
gemspec

def location_for(place, fake_version = nil)
  if place =~ /^(git:[^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

group :testing do
  gem "beaker", *location_for(ENV['BEAKER_VERSION'] || '~> 5.0')
end
