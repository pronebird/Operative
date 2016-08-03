# Operative

[![CI Status](http://img.shields.io/travis/Kabal/Operative.svg?style=flat)](https://travis-ci.org/Kabal/Operative)
[![Version](https://img.shields.io/cocoapods/v/Operative.svg?style=flat)](http://cocoapods.org/pods/Operative)
[![License](https://img.shields.io/cocoapods/l/Operative.svg?style=flat)](http://cocoapods.org/pods/Operative)
[![Platform](https://img.shields.io/cocoapods/p/Operative.svg?style=flat)](http://cocoapods.org/pods/Operative)

Objective-C port of the Swift code provided for the WWDC presentation "Advanced NSOperations"

Not really tested yet.. probably has bugs.

TODO:
 - Not all of the 'Conditions' are ported yet
 - Better example app
 - Tests!?!


## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Operative is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Operative"
```

## App extensions

Add the following line to your podspec in order to compiler Operative for extension:

```ruby
post_install do |installer|
  # NOTE: If you are using a CocoaPods version prior to 0.38, replace `pods_project` with `project` on the below line
  installer.pods_project.targets.each do |target|
    if target.name.end_with? "Operative"
      target.build_configurations.each do |build_configuration|
        if build_configuration.build_settings['APPLICATION_EXTENSION_API_ONLY'] == 'YES'
          build_configuration.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'OP_TARGET_IS_EXTENSION=1']
        end
      end
    end
  end
end
```

## Author

Tom Wilson, tom@toms-stuff.net

## License

Operative is available under the MIT license. See the LICENSE file for more info.
