# CHANGELOG

## master

## v1.5.0

* Add support for Cobertura.  
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
