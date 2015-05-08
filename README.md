

![Slather Logo](https://raw.githubusercontent.com/venmo/slather/master/docs/logo.jpg)

[![Gem Version](https://badge.fury.io/rb/slather.svg)](http://badge.fury.io/rb/slather)
[![Build Status](https://travis-ci.org/venmo/slather.svg?branch=master)](https://travis-ci.org/venmo/slather)
[![Coverage Status](https://coveralls.io/repos/venmo/slather/badge.svg?branch=ayanonagon%2Fcoveralls)](https://coveralls.io/r/venmo/slather?branch=ayanonagon%2Fcoveralls)

Generate test coverage reports for Xcode projects & hook it into CI.

### Projects that use Slather

| Project | Coverage |
| ------- |:--------:|
| [Parsimmon](https://github.com/ayanonagon/Parsimmon) | [![Parsimmon Coverage](https://coveralls.io/repos/ayanonagon/Parsimmon/badge.svg?branch=master)](https://coveralls.io/r/ayanonagon/Parsimmon?branch=master) |
| [VENCore](https://github.com/venmo/VENCore) | [![VENCore Coverage](https://coveralls.io/repos/venmo/VENCore/badge.svg?branch=master)](https://coveralls.io/r/venmo/VENCore?branch=master) |
| [CGFloatType](https://github.com/kylef/CGFloatType) | [![CGFloatType Coverage](https://coveralls.io/repos/kylef/CGFloatType/badge.svg?branch=master)](https://coveralls.io/r/kylef/CGFloatType?branch=master) |
| [DAZABTest](https://github.com/dasmer/DAZABTest) | [![DAZABTest Coverage](https://coveralls.io/repos/dasmer/DAZABTest/badge.svg?branch=master)](https://coveralls.io/r/dasmer/DAZABTest?branch=master) |
| [TBStateMachine](https://github.com/tarbrain/TBStateMachine) | [![TBStateMachine Coverage](https://coveralls.io/repos/tarbrain/TBStateMachine/badge.svg?branch=master)](https://coveralls.io/r/tarbrain/TBStateMachine?branch=master) |

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'slather'
```

And then execute:

```sh
$ bundle
```

## Usage

Setup your project for test coverage:

```sh
$ slather setup path/to/project.xcodeproj
```

This will enable the `Generate Test Coverage` and `Instrument Program Flow` flags for your project.


To test if you're ready to generate test coverage, run your test suite on your project, and then run:

```sh
$ slather coverage -s path/to/project.xcodeproj
```

### Coveralls

Login to [Coveralls](https://coveralls.io/) and enable your repository. Right now, `slather` supports Coveralls via [Travis CI](https://travis-ci.org) and [CircleCI](https://circleci.com).

Make a `.slather.yml` file:

```yml
# .slather.yml

coverage_service: coveralls
xcodeproj: path/to/project.xcodeproj
ignore:
  - ExamplePodCode/*
  - ProjectTestsGroup/*
```

And then in your `.travis.yml` or `circle.yml`, call `slather` after a successful build:

```yml
# .travis.yml

before_install: rvm use $RVM_RUBY_VERSION
install: bundle install --without=documentation --path ../travis_bundle_dir
after_success: slather
```

```yml
# circle.yml

test:
  post:
    - bundle exec slather

```

#### Travis CI Pro

To use Coveralls with Travis CI Pro (for private repos), add following lines along with other settings to `.slather.yml`:

```yml
# .slather.yml

ci_service: travis_pro
coverage_access_token: <YOUR ACCESS TOKEN>
```

The coverage token can be found at [Coveralls](https://coveralls.io/) repo page. Or it can be passed in via the `COVERAGE_ACCESS_TOKEN` environment var.

### Cobertura

To create a Cobertura XML report set `cobertura_xml` as coverage service inside your `.slather.yml`. Optionally you can define an output directory for the XML report:

```yml
# .slather.yml

coverage_service: cobertura_xml
xcodeproj: path/to/project.xcodeproj
source_directory: path/to/sources/to/include
output_directory: path/to/xml_report
ignore:
  - ExamplePodCode/*
  - ProjectTestsGroup/*
```

Or use the command line options `--cobertura-xml` or `-x` and `--output_directory`:

```sh
$ slather coverage -x --output-directory path/to/xml_report
```

### Coverage for code included via CocoaPods

If you're trying to compute the coverage of code that has been included via
CocoaPods, you will need to tell CocoaPods to use the slather plugin by
adding the following to your `Podfile`.

```ruby
plugin 'slather'
```

You will also need to tell slather where to find the source files for your Pod.

```yml
# .slather.yml

source_directory: Pods/AFNetworking
```

### Custom Build Directory

Slather will look for the test coverage files in `DerivedData` by default. If you send build output to a custom location, like [this](https://github.com/erikdoe/ocmock/blob/7f4d22b38eedf1bb9a12ab1591ac0a5d436db61a/Tools/travis.sh#L12), then you should also set the `build_directory` property in `.slather.yml`

## Contributing

We’d love to see your ideas for improving this library! The best way to contribute is by submitting a pull request. We’ll do our best to respond to your patch as soon as possible. You can also submit a [new GitHub issue](https://github.com/venmo/slather/issues/new) if you find bugs or have questions. :octocat:

Please make sure to follow our general coding style and add test coverage for new features!

## Contributors

* [@tpoulos](https://github.com/tpoulos), the perfect logo.
* [@ayanonagon](https://github.com/ayanonagon) and [@kylef](https://github.com/kylef), feedback and testing.
* [@jhersh](https://github.com/jhersh), CircleCI support.
