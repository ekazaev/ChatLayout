<p align="right">
<a href="https://websummit.com"><img src="https://habrastorage.org/webt/jh/an/e-/jhane-_nukqskoq49iqidftm0-4.png" alt="Websummit"/></a>
</p>

# ChatLayout

[![CI Status](https://travis-ci.org/ekazaev/ChatLayout.svg?branch=master&style=flat)](https://travis-ci.org/github/ekazaev/ChatLayout)
[![Release](https://img.shields.io/github/release/ekazaev/ChatLayout.svg?style=flat&color=darkcyan)](https://github.com/ekazaev/ChatLayout/releases)
[![Version](https://img.shields.io/cocoapods/v/ChatLayout.svg?style=flat)](https://cocoapods.org/pods/ChatLayout)
[![Documentation](https://ekazaev.github.io/ChatLayout/badge.svg)](https://ekazaev.github.io/ChatLayout/)
[![Codecov](https://codecov.io/gh/ekazaev/ChatLayout/branch/master/graph/badge.svg)](https://codecov.io/gh/ekazaev/ChatLayout)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BA51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift 5.2](https://img.shields.io/badge/language-Swift5.2-orange.svg?style=flat)](https://developer.apple.com/swift)
[![Platform iOS](https://img.shields.io/badge/platform-iOS%2012%20—%20iOS%2014-yellow.svg)](https://www.apple.com/ios)

## Table of contents

- [About](#about)
- [Features](#features)
    - [What ChatLayout doesn't provide (And why it is good)](#what-chatlayout-doesnt-provide-and-why-it-is-good)
- [Requirements](#requirements)
- [Example](#example)
- [Installation](#installation)
- [About `UICollectionViewDiffableDataSource`](#about-uicollectionviewdiffabledatasource)
- [Contributing](#contributing)
- [Todo](#todo)
- [License](#license)
- [Articles](#articles)
- [Author](#author)

## About

`ChatLayout` is an alternative solution to [MessageKit](https://github.com/MessageKit/MessageKit). It uses custom 
`UICollectionViewLayout` to provide you full control over the presentation as well as all the tools available in 
`UICollectionView`.

## Features

- Supports dynamic cells and supplementary view sizes.
- Animated insertion/deletion/reloading/moving of the items.
- Keeps content of the last visible item at the top or bottom of the `UICollectionView` during updates.
- Provides tools for precise scrolling to the required item.
- Shipped with generic container views to simplify the custom items implementation.  

![](https://habrastorage.org/webt/jt/gq/sl/jtgqsluujffi4-jnxeikbwtyyu0.gif)
![](https://habrastorage.org/webt/b7/cu/3s/b7cu3su6uk4hw1kqg3_ky3uklu4.gif)
![](https://habrastorage.org/webt/sv/ul/cq/svulcqg5ompgyhp-pjxy1tyiie4.gif)
![](https://habrastorage.org/webt/bq/kw/xg/bqkwxgggxnxlqyzau36utlwcyui.gif)
![](https://habrastorage.org/webt/hn/ez/gq/hnezgqezp8vxg8vy8z7_ozetra0.gif)

### What ChatLayout doesn't provide (And why it is good)

`ChatLayout` is the custom `UICollectionViewLayout`, so:

- You don't have to extend or override any custom `UIViewController` or `UICollectionView`. You need to instantiate them 
yourself and use them the way you like. 

- `ChatLayout` does not rely on modified `UICollectionViewFlowLayout` nor does it rotate your `UICollectionView` upside-down. 
This means you can use your views as if they would be regular cells within `UICollectionView`. You can benefit from using the 
default `UIKit` implementations of `adjustedContextInsets` (and others) because your view controller is a normal view 
controller without any hacks or tricks.

- `ChatLayout` doesn't require you to calculate all the cell sizes before it renders them on the screen. You can fully use
auto-layout constraints and rely on the fact that the correct size will be calculated in the runtime. However, `ChatLayout` 
as any other `UICollectionViewLayout` will benefit from you providing the estimated sizes of your cells as it will allow you 
to get better performance. 

- `ChatLayout` doesn't enforce you to use any specific data model. You can store your messages and update `UICollectionView`
the way you like. The only thing you need is to respect the natural boundaries that `UICollectionView` have and correctly
implement `UICollectionViewDataSource`. The Example app uses [DifferenceKit](https://github.com/ra1028/DifferenceKit) to 
process changes in the data model.

- `ChatLayout` doesn't enforce you to use any specific `UIView`s to create your collection cells. You can create them the way 
you like. It can be any `UICollectionViewCell` or `UICollectionReusableView`. There are some generic `UIView`s bundled with
the library that may help you to build them faster. However, you do not have to use them. 

- `ChatLayout` doesn't handle the keyboard appearance behavior. You have to implement
that yourself from scratch or use the library you are already using in your project. It gives you full control over the 
keyboard presentation. The only thing you have to do is to update the `contentInsets` of your `UICollectionView`.

- `ChatLayout` doesn't provide you any input control. You can use any one you like and customise it the way you like. 
The Example app for instance uses [InputBarAccessoryView](https://github.com/nathantannar4/InputBarAccessoryView).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

`ChatLayout` is available through [CocoaPods](https://cocoapods.org), [Carthage](https://github.com/Carthage/Carthage) 
and [SwiftPM](https://github.com/apple/swift-package-manager). See the `Example` app for the usage details.

If you are using cocoapods you can install the whole package using `pod 'ChatLayout'`. If you do not need the additional
components provided, you can install only the layout itself using `pod 'ChatLayout/Core'`

**NB: `ChatLayout` is in pre-release state, so it doesn't respect the [semantic versioning](https://semver.org) at
this moment and may introduce breaking changes in further versions. It is recommended to link the dependency to
the exact version number in the dependency manager you use and increase the release version manually.**

## About `UICollectionViewDiffableDataSource`

`ChatLayout` can process any update commands that you send to your `UICollectionView`, so you can use 
`UICollectionViewDiffableDataSource` as well. But you have to keep in mind that `UICollectionViewDiffableDataSource` 
does not support the reloading of cells out of the box if you are relying on the `Hashable` protocol implementation.
It will delete the changed cell and insert the new version of said cell. That may lead to strange animations on 
the screen, especially when the reloaded cell changes its size. In order to get the best behaviour of the update animation 
I would strongly recommend you rely on [DifferenceKit](https://github.com/ra1028/DifferenceKit) to process the model changes.
The Example app does it as well.

## Contributing

`ChatLayout` is in active development, and we welcome your contributions.

If you’d like to contribute to this repo, please
read [the contribution guidelines](https://github.com/ekazaev/route-composer/blob/master/CONTRIBUTING.md).

## Todo

- [ ] Improve the test coverage
- [ ] Provide proper documentation

## License

`ChatLayout` is distributed under [the MIT license](https://github.com/ekazaev/ChatLayout/blob/master/LICENSE).

`ChatLayout` is provided for your use, free-of-charge, on an as-is basis. We make no guarantees, promises or
apologies. *Caveat developer.*

## Articles

Russian:
  - [Мой Covid-19 lockdown проект, или, как я полез в кастомный UICollectionViewLayout и получил ChatLayout](https://habr.com/ru/post/523492/)

## Author
  
Evgeny Kazaev, eugene.kazaev@gmail.com. Twitter [ekazaev](https://twitter.com/EKazaev)

*I am happy to answer any questions you may have. Just create a [new issue](https://github.com/ekazaev/ChatLayout/issues/new).*

