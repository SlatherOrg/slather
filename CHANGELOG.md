# CHANGELOG

## master
* Xcode 7.3 compatibility (updated path returned by `profdata_coverage_dir`)
  [Kent Sutherland](https://github.com/ksuther)
  [#125](https://github.com/SlatherOrg/slather/issues/125), [#169](https://github.com/SlatherOrg/slather/pull/169)

* Improve matching of xctest bundles when using `--binary-basename`
  [Kent Sutherland](https://github.com/ksuther)
  [#167](https://github.com/SlatherOrg/slather/pull/167)

* Build Statistic Reporting for TeamCity
  [Michael Myers](https://github.com/michaelmyers)
  [#150](https://github.com/SlatherOrg/slather/pull/150)

## v2.0.1

* Fixes how `profdata_coverage_dir` is created.
  [guidomb](https://github.com/guidomb)
  [#145](https://github.com/SlatherOrg/slather/pull/145)

## v2.0.0
* Correct html rendering when using profdata format   
  [cutz](https://github.com/cutz)
  [#124](https://github.com/SlatherOrg/slather/pull/124)

* Making HTML directory self contained   
  [Colin Cornaby](https://github.com/colincornaby)
  [#137](https://github.com/SlatherOrg/slather/pull/137)

* Add `binary_basename` configuration option   
  [Boris Bügling](https://github.com/neonichu)
  [#128](https://github.com/SlatherOrg/slather/pull/128)

* Add support to profdata file format   
  [Simone Civetta](https://github.com/viteinfinite)
  [Olivier Halligon](https://github.com/AliSoftware)
  [Matt Delves](https://github.com/mattdelves)
  [Pierre-Marc Airoldi](https://github.com/petester42)
  [#92](https://github.com/venmo/slather/pull/92)

## v1.8.3
* Add buildkite support to coveralls   
  [David Hardiman](https://github.com/dhardiman)
  [#98](https://github.com/venmo/slather/pull/98)
* Update to xcodeproj 0.28.0 to avoid collisions with Cocoapods 0.39.0   
  [Julian Krumow](https://github.com/tarbrain)   
  [#106](https://github.com/venmo/slather/pull/106)/[#109](https://github.com/venmo/slather/pull/109)

## v1.8.1
* Fixed dependency conflict with CocoaPods v0.38
* Updated usage of cocoapods plugin API since it has changed in v0.38   
  [Julian Krumow](https://github.com/tarbrain)
  [#95](https://github.com/venmo/slather/pull/95)

## v1.7.0
* Objective-C++ support  
  [ben-ng](https://github.com/ben-ng)
  [#63](https://github.com/venmo/slather/pull/63)

## v1.6.0
* Add CircleCI support  
  [Jonathan Hersh](https://github.com/jhersh)
  [#55](https://github.com/venmo/slather/pull/55)

## v1.5.4

* Fix calculation of branch coverage when a class has no branches  
  [Julian Krumow](https://github.com/tarbrain)
  [#40](https://github.com/venmo/slather/pull/40)

* Always consider empty files as 100% tested  
  [Boris Bügling](https://github.com/neonichu)
  [#45](https://github.com/venmo/slather/pull/45)

## v1.5.2

* Add an option to define the output directory for cobertura xml reports  
  [Julian Krumow](https://github.com/tarbrain)
  [#37](https://github.com/venmo/slather/pull/37)

## v1.5.1

* Avoid crashes when coverage data is empty
* Fix bug which prevented source files without coverage data to be included in Cobertura xml report  
  [Julian Krumow](https://github.com/tarbrain)
  [#34](https://github.com/venmo/slather/pull/34)

## v1.5.0

* Add support for Cobertura  
  [Julian Krumow](https://github.com/tarbrain)
  [#30](https://github.com/venmo/slather/pull/30)

## v1.4.0

* Implement a CocoaPods plugin  
  [Kyle Fuller](https://github.com/kylef)
  [#25](https://github.com/venmo/slather/pull/25)

* Avoid getting 'Infinity' or 'NaN' when dividing by 0.0  
  [Mark Larsen](https://github.com/marklarr)

* Ignore exceptions about files not existing by using 'force'  
  [Mark Larsen](https://github.com/marklarr)

## v1.3.0

* Add Gutter JSON output  
  [Boris Bügling](https://github.com/neonichu)
  [#24](https://github.com/venmo/slather/pull/24)

## v1.2.1

* Fix typo --simple-output description  
  [Ayaka Nonaka](https://github.com/ayanonagon)
  [#19](https://github.com/venmo/slather/pull/19)

* Remove broken travis pro support  
  [Mark Larsen](https://github.com/marklarr)
  [#22](https://github.com/venmo/slather/pull/22)

* Fix exception for files without `@interface` or `@implementation`  
  [Piet Brauer](https://github.com/pietbrauer)
  [#23](https://github.com/venmo/slather/pull/23)

## v1.2.0

* Remove duplicate coverage files, favoring the file with higher coverage.  
  [Ayaka Nonaka](https://github.com/ayanonagon)
  [#16](https://github.com/venmo/slather/pull/16)

* Add support for access token and Travis Pro  
  [Chris Maddern](https://github.com/chrismaddern)
  [#17](https://github.com/venmo/slather/pull/17)

## v1.1.0

* Support for code coverage of pods  
  [Mark Larsen](https://github.com/marklarr)

## v1.0.1

* Fix coverage search for files that contain spaces  
  [Mark Larsen](https://github.com/marklarr)

## v1.0.0

* beautified README  
  [Ayaka Nonaka](https://github.com/ayanonagon)
  [#4](https://github.com/venmo/slather/pull/4)  
  [Kyle Fuller](https://github.com/kylef)
  [#5](https://github.com/venmo/slather/pull/5)

* Add Travis automated builds  
  [Mark Larsen](https://github.com/marklarr)
  [#6](https://github.com/venmo/slather/pull/6)

* Use `||=` instead of `unless`  
  [Ayaka Nonaka](https://github.com/ayanonagon)
  [#7](https://github.com/venmo/slather/pull/7)

## v0.0.31

* find source files via pbx proj rather than file system  
  [Mark Larsen](https://github.com/marklarr)

## v0.0.3

* Initial Release  
  [Mark Larsen](https://github.com/marklarr)
