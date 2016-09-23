# Lug [![Build Status](https://travis-ci.org/munshkr/lug.svg?branch=master)](https://travis-ci.org/munshkr/lug)

A small Ruby logger for debugging libraries and applications.  Pretty much a
clone of [debug](https://github.com/visionmedia/debug) for Node.js

## Features

* Smaller and faster than Ruby's logger
* Colorized output for tty output devices (like stderr)
* Filter log messages by namespace
* Standard logger interface (responds to #debug, #warn, #error, etc.)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lug'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lug

## Usage

TODO: Write usage instructions here

## Benchmark

Performance comparison between Ruby's Logger class and Lug logger classes.
`TtyLogger` colorizes output and calculates elapsed time between lines.

```
                           user     system      total        real
Logger#debug           1.340000   0.190000   1.530000 (  1.537950)
Lug::Logger#log        0.680000   0.030000   0.710000 (  0.713254)
Lug::TtyLogger#log     0.690000   0.030000   0.720000 (  0.713585)
Lug::Logger#debug      0.850000   0.040000   0.890000 (  0.885118)
Lug::TtyLogger#debug   0.880000   0.020000   0.900000 (  0.890095)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/munshkr/lug. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
