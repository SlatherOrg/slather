# CHANGELOG

## v2.5.0

* Fixed activesupport and cocoapods dependencies
  [daneov](https://github.com/daneov)
  [#456](https://github.com/SlatherOrg/slather/pull/467)

* Fixed typo in documentation
  [descorp](https://github.com/descorp)
  [#456](https://github.com/SlatherOrg/slather/pull/463)

## v2.4.9

* Added support for Sonarqube output
  [adellibovi](https://github.com/adellibovi)
  [#456](https://github.com/SlatherOrg/slather/pull/456)

## v2.4.8

* Optimize performance for many binaries
  [cltnschlosser](https://github.com/cltnschlosser)
  [#455](https://github.com/SlatherOrg/slather/pull/455)

* Don't generate line 0 in profdata_coverage_file.rb from line with error
  [tthbalazs](https://github.com/tthbalazs)
  [#449](https://github.com/SlatherOrg/slather/pull/449)

* coveralls dependency update
  [GRiMe2D](https://github.com/GRiMe2D)
  [#448](https://github.com/SlatherOrg/slather/pull/448)

## v2.4.7

* Update dependencies
  [dnedrow](https://github.com/dnedrow)

* Fixed errors when llvm-cov argument length exceeds ARG_MAX
  [weibel](https://github.com/weibel)
  [#414](https://github.com/SlatherOrg/slather/pull/414)

* Show "No coverage directory found." instead of "implicit conversion nil into String"
  [phimage](https://github.com/phimage)
  [#381](https://github.com/SlatherOrg/slather/pull/381) [#341](https://github.com/SlatherOrg/slather/issues/341)

## v2.4.6

* Fix .dSYM and .swiftmodule files filtering in find_binary_files()
  [krin-san](https://github.com/krin-san)
  [#368](https://github.com/SlatherOrg/slather/pull/368)

* Fixed loading coverage for a single source file
  [blackm00n](https://github.com/blackm00n)
  [#377](https://github.com/SlatherOrg/slather/pull/377) [#398](https://github.com/SlatherOrg/slather/pull/398)

* Fixed truncated file list in HTML export
  [miroslavkovac](https://github.com/miroslavkovac)
  [#402](https://github.com/SlatherOrg/slather/pull/402) [#261](https://github.com/SlatherOrg/slather/issues/261)

## v2.4.5

* Support for specifying a specific binary architecture
  [ksuther](https://github.com/ksuther), [nickolas-pohilets](https://github.com/nickolas-pohilets)
  [#367](https://github.com/SlatherOrg/slather/pull/367)

* Added absolute statement count to simple output (instead of showing just a percentage)
  [barrault01](https://github.com/barrault01), [ivanbrunel](https://github.com/ivanbruel)
  [#365](https://github.com/SlatherOrg/slather/pull/365)

* Updated nokogiri dependency version
  [#363](https://github.com/SlatherOrg/slather/issues/363), [#366](https://github.com/SlatherOrg/slather/pull/366)

* slather now requires ruby 2.1 or later (10.13 ships with 2.3.3)

## v2.4.4

* Added llvm-cov output format
  [sgtsquiggs](https://github.com/sgtsquiggs) [#354](https://github.com/SlatherOrg/slather/pull/354)

* Exclude swiftmodule from product search
  [lampietti](https://github.com/lampietti) [#352](https://github.com/SlatherOrg/slather/pull/352)

## v2.4.3

* Initial Xcode 9 support
  [ksuther](https://github.com/ksuther) [#339](https://github.com/SlatherOrg/slather/pull/339), [ivanbrunel](https://github.com/ivanbruel) [#321](https://github.com/SlatherOrg/slather/pull/321), [FDREAL](https://github.com/FDREAL) [#338](https://github.com/SlatherOrg/slather/pull/338)

* Add `--json` output option for basic JSON format not specific to any particular service.
  [ileitch](https://github.com/ileitch)
  [#318](https://github.com/SlatherOrg/slather/pull/318)

## v2.4.2

* Restored support for Xcode 7  
  [ButkiewiczP](https://github.com/ButkiewiczP)
  [#304](https://github.com/slatherOrg/slather/pull/308)

* Added Jenkins Pipeline support for Coveralls  
  [daneov](https://github.com/daneov)
  [#304](https://github.com/slatherOrg/slather/pull/304)

## v2.4.1

* Add `--configuration` option  
  [thasegaw](https://github.com/thasegaw)
  [#294](https://github.com/slatherOrg/slather/pull/294)

* Fix misdetection of Xcode version if Spotlight hasn't indexed Xcode yet  
  [ksuther](https://github.com/ksuther)
  [#298](https://github.com/slatherOrg/slather/pull/298)

* Better verbose message when no binaries are found  
  [ksuther](https://github.com/ksuther)
  [#300](https://github.com/slatherOrg/slather/pull/300)

## v2.4.0

* Xcode 8.3 support.
  [ksuther](https://github.com/ksuther)
  [#291](https://github.com/SlatherOrg/slather/pull/291)

* Automatically ignore headers in Xcode platform SDKs.  
  [ksuther](https://github.com/ksuther)
  [#286](https://github.com/SlatherOrg/slather/pull/286)

* Automatically handle schemes with multiple build or test targets  
  [serges147](https://github.com/serges147)
  [#275](https://github.com/SlatherOrg/slather/pull/275)

* Added TeamCity as a CI service option  
  [joshrlesch](https://github.com/joshrlesch)
  [#279](https://github.com/SlatherOrg/slather/pull/279)

* Handle UTF-8 characters correctly in HTML reports  
  [0xced](https://github.com/0xced)
  [#259](https://github.com/SlatherOrg/slather/pull/259)

* Fix hanging `xcodebuild` invocation when getting derived data path.  
  [arthurtoper](https://github.com/arthurtoper)
  [#238](https://github.com/SlatherOrg/slather/pull/238), [#197](https://github.com/SlatherOrg/slather/issues/197), [#212](https://github.com/SlatherOrg/slather/issues/212), [#234](https://github.com/SlatherOrg/slather/issues/234)

## v2.3.0

* Fixes broken fallback value of `input_format` inside `configure_input_format`  
  [sbhklr](https://github.com/sbhklr)
  [#233](https://github.com/SlatherOrg/slather/pull/233), [#232](https://github.com/SlatherOrg/slather/issues/232)

* Add `--travispro` flag  
  [sbhklr](https://github.com/sbhklr)
  [#223](https://github.com/SlatherOrg/slather/pull/223), [#219](https://github.com/SlatherOrg/slather/issues/219)

* Fixes silent failure in case of unsuccessful upload to Coveralls  
  [sbhklr](https://github.com/sbhklr)
  [#222](https://github.com/SlatherOrg/slather/pull/222), [#217](https://github.com/SlatherOrg/slather/issues/217)

## v2.2.1

* Make `project.coverage_files` public  
* Add docs attribute reader to `project.rb`  
  [bootstraponline](https://github.com/bootstraponline)
  [#209](https://github.com/SlatherOrg/slather/pull/209)

* Add `--decimals` flag  
  [bootstraponline](https://github.com/bootstraponline)
  [#207](https://github.com/SlatherOrg/slather/pull/207)

* Add `slather version` command  
  [bootstraponline](https://github.com/bootstraponline)
  [#208](https://github.com/SlatherOrg/slather/pull/208)

## v2.2.0

* Fix nil crash in `project.rb` derived_data_path  
  [bootstraponline](https://github.com/bootstraponline)
  [#203](https://github.com/SlatherOrg/slather/pull/203)

* Fix for correct line number for lines that are hit thousands or millions of time in llvm-cov.  
  [Mihai Parv](https://github.com/mihaiparv)
  [#202](https://github.com/SlatherOrg/slather/pull/202), [#196](https://github.com/SlatherOrg/slather/issues/196)

* Generate coverate for multiple binaries by passing multiple `--binary-basename` or `--binary-file` arguments, or by using an array in `.slather.yml`  
  [Kent Sutherland](https://github.com/ksuther)
  [#188](https://github.com/SlatherOrg/slather/pull/188)

* Support for specifying source file patterns using the `--source-files` option or the source_files key in `.slather.yml`  
  [Matej Bukovinski](https://github.com/matej)
  [#201](https://github.com/SlatherOrg/slather/pull/201)

* Improve getting schemes. Looks for user scheme in case no shared scheme is found.  
  [Matyas Hlavacek](https://github.com/matyashlavacek)
  [#182](https://github.com/SlatherOrg/slather/issues/182)

* Search Xcode workspaces for schemes. Workspaces are checked if no matching scheme is found in the project.  
  [Kent Sutherland](https://github.com/ksuther)
  [#193](https://github.com/SlatherOrg/slather/pull/193), [#191](https://github.com/SlatherOrg/slather/issues/191)

* Fix for hit counts in thousands or millions being output as floats intead of integers  
  [Carl Hill-Popper](https://github.com/chillpop)
  [#190](https://github.com/SlatherOrg/slather/pull/190)

## v2.1.0

* Support for Xcode workspaces. Define `workspace` configuration in `.slather.yml` or use the `--workspace` argument if you build in a workspace.
* Improved slather error messages  
  [Kent Sutherland](https://github.com/ksuther)
  [#178](https://github.com/SlatherOrg/slather/issues/178)

* Re-add Teamcity support  
  [Boris Bügling](https://github.com/neonichu)
  [#180](https://github.com/SlatherOrg/slather/pull/180)

* Show lines that are hit thousands or millions of time in llvm-cov  
  [Kent Sutherland](https://github.com/ksuther)
  [#179](https://github.com/SlatherOrg/slather/pull/179)

* Fix for setting scheme/workspace from configuration file.  
  [Boris Bügling](https://github.com/neonichu)
  [#183](https://github.com/SlatherOrg/slather/pull/183)

## v2.0.2

* Escape the link to file names properly  
  [Thomas Mellenthin](https://github.com/melle)
  [#158](https://github.com/SlatherOrg/slather/pull/158)

* Product info is now read from schemes. Specify a scheme in `.slather.yml` or with the `--scheme` argument to ensure consistent results. Automatically detect the derived data directory from `xcodebuild`  
  [Kent Sutherland](https://github.com/ksuther)
  [#174](https://github.com/SlatherOrg/slather/pull/174)

* Xcode 7.3 compatibility (updated path returned by `profdata_coverage_dir`)  
  [Kent Sutherland](https://github.com/ksuther)
  [#125](https://github.com/SlatherOrg/slather/issues/125), [#169](https://github.com/SlatherOrg/slather/pull/169)

* Improve matching of xctest bundles when using `--binary-basename`  
  [Kent Sutherland](https://github.com/ksuther)
  [#167](https://github.com/SlatherOrg/slather/pull/167)

* Build Statistic Reporting for TeamCity  
  [Michael Myers](https://github.com/michaelmyers)
  [#150](https://github.com/SlatherOrg/slather/pull/150)

* Use named classes for subcommands in bin/slather  
  [bootstraponline](https://github.com/bootstraponline)
  [#170](https://github.com/SlatherOrg/slather/pull/170)

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
