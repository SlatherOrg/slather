![Slather Logo](https://raw.githubusercontent.com/venmo/slather/master/docs/logo.jpg?token=760261__eyJzY29wZSI6IlJhd0Jsb2I6dmVubW8vc2xhdGhlci9tYXN0ZXIvZG9jcy9sb2dvLmpwZyIsImV4cGlyZXMiOjE0MDQzNDU3NzJ9--825fd039ab7c3fe638d8dc862afd790bcabd162f)

Generate test coverage reports for Xcode projects. Apply tests liberally.

### Projects that use Slather
* [Parsimmon](https://github.com/ayanonagon/Parsimmon) [![Parsimmon Coverage](https://coveralls.io/repos/ayanonagon/Parsimmon/badge.png?branch=master)](https://coveralls.io/r/ayanonagon/Parsimmon?branch=master)
* [VENCore](https://github.com/venmo/VENCore) [![Coverage Status](https://coveralls.io/repos/venmo/VENCore/badge.png?branch=marklarr%2Fslather)](https://coveralls.io/r/venmo/VENCore?branch=marklarr%2Fslather)

## Installation

Add this line to your application's Gemfile:

    gem 'slather'

And then execute:

    $ bundle

## Usage

Setup your project for test coverage:

    $ slather setup path/to/project.xcodeproj

This will enable the `Generate Test Coverage` and `Instrument Program Flow` flags for your project.


To test if you're ready to generate test coverage, run your test suite on your project, and then run:

    $ slather coverage -s path/to/project.xcodeproj

### Coveralls

Login to https://coveralls.io/ and enable your repository. Right now, `slather` only supports coveralls via Travis CI.

Make a `.slather.yml` file:

```yml
# .slather.yml

coverage_service: coveralls
xcodeproj: path/to/project.xcodeproj
ignore:
  - ExamplePodCode/*
  - ProjectTestsGroup/*
```

And then in your `.travis.yml`, call `slather` after a successful_build

```yml
# .travis.yml

after_success: slather
```

### Custom Build Directory

Slather will look for the test coverage files in `DerivedData` by default. If you send build output to a custom location, like [this](https://github.com/erikdoe/ocmock/blob/master/Tools/travis.sh#L12), then you should also set the `build_directory` property in `.slather.yml`

## Contributing

We'd love to see your ideas for improving this library! The best way to contribute is by submitting a pull request. We'll do our best to respond to your patch as soon as possible. You can also submit a [new Github issue](https://github.com/venmo/slather/issues/new) if you find bugs or have questions. :octocat:

Please make sure to follow our general coding style and add test coverage for new features!

## Contributors

* [@tpoulos](https://github.com/tpoulos), the perfect logo.
* [@ayanonagon](https://github.com/ayanonagon) and [@kylef](https://github.com/kylef), feedback and testing.
