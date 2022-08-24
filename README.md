<p align="right">
<a href="https://websummit.com"><img src="https://habrastorage.org/webt/jh/an/e-/jhane-_nukqskoq49iqidftm0-4.png" alt="Websummit"/></a>
</p>

# ChatLayout

[![CI Status](https://travis-ci.org/ekazaev/ChatLayout.svg?branch=master&style=flat)](https://travis-ci.org/github/ekazaev/ChatLayout)
[![Release](https://img.shields.io/github/release/ekazaev/ChatLayout.svg?style=flat&color=darkcyan)](https://github.com/ekazaev/ChatLayout/releases)
[![Version](https://img.shields.io/cocoapods/v/ChatLayout.svg?style=flat)](https://cocoapods.org/pods/ChatLayout)
[![Documentation](https://ekazaev.github.io/ChatLayout/badge.svg)](https://ekazaev.github.io/ChatLayout/)
[![Codecov](https://codecov.io/gh/ekazaev/ChatLayout/branch/master/graph/badge.svg)](https://codecov.io/gh/ekazaev/ChatLayout)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/b97c279a50984376ab2649f5a7d09e69)](https://www.codacy.com/gh/ekazaev/ChatLayout/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ekazaev/ChatLayout&amp;utm_campaign=Badge_Grade)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BA51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift 5.7](https://img.shields.io/badge/language-Swift5.7-orange.svg?style=flat)](https://developer.apple.com/swift)
[![Platform iOS](https://img.shields.io/badge/platform-iOS%2012%20—%20iOS%2016-yellow.svg)](https://www.apple.com/ios)

<p align="center">
<img src="https://habrastorage.org/webt/ji/ba/dj/jibadjc0hul-fzfwxm2w0ywdutg.png" />
</p>

## Table of contents

- [About](#about)
- [Features](#features)
    - [What ChatLayout doesn't provide (And why it is good)](#what-chatlayout-doesnt-provide-and-why-it-is-good)
- [Requirements](#requirements)
- [Example](#example)
- [Installation](#installation)
- [Contributing](#contributing)
- [Todo](#todo)
    - [About `UICollectionViewDiffableDataSource`](#about-uicollectionviewdiffabledatasource)
    - [About Supplementary Views](#about-supplementary-views)
    - [About Texture](#about-texture)
    - [About animation](#about-animation)
    - [About sticky headers or footers](#about-sticky-headers-or-footers)
- [License](#license)
- [Articles](#articles)
- [Sponsor this project](#sponsor-this-project)
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
![](https://habrastorage.org/webt/gn/ny/qe/gnnyqepf46r4zdhyb4oug8vywvc.gif)
![](https://habrastorage.org/webt/t9/b7/4r/t9b74rdyrkf8lszjuhj_vrbp7-s.gif)
![](https://habrastorage.org/webt/nv/vr/js/nvvrjsqk0fzutq0y-uubjewyqjm.gif)

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

## Contributing

`ChatLayout` is in active development, and we welcome your contributions.

If you’d like to contribute to this repo, please
read [the contribution guidelines](https://github.com/ekazaev/route-composer/blob/master/CONTRIBUTING.md).

## Todo

- [ ] Improve the test coverage

### About `UICollectionViewDiffableDataSource`

`ChatLayout` can process any update commands that you send to your `UICollectionView`, so you can use 
`UICollectionViewDiffableDataSource` as well. But you have to keep in mind that `UICollectionViewDiffableDataSource` 
does not support the reloading of cells out of the box if you are relying on the `Hashable` protocol implementation.
It will delete the changed cell and insert the new version of said cell. That may lead to strange animations on 
the screen, especially when the reloaded cell changes its size. In order to get the best behaviour of the update animation 
I would strongly recommend you rely on [DifferenceKit](https://github.com/ra1028/DifferenceKit) or a similar library 
to process the model changes. The Example app does it as well.

### About Supplementary Views

It can be tempting and it may look like it is the right way to go, but **do not** use supplementary views to decorate your
messages or groups of them. `UICollectionView` processes them in a different order: `UICollectionViewCell`s first and 
only after switches to `UICollectionReusableView`s. You will most likely face some unexpected behaviour during the animation.

### About Texture

`ChatLayout` can be used together with [Texture](https://github.com/TextureGroup/Texture) to improve the auto-layout performance. 
But keep in mind that it's default wrapper is hardcoded to work exclusively with `UICollectionViewFlowLayout`. 
[See issue](https://github.com/TextureGroup/Texture/issues/1959).
You will have to implement `ChatLayoutDelegate` yourself and propagate the node size manually.

### About animation

If you see a strange or unexpected animation during the updates, check your data model and **the commands you send to the
`UICollectionView`'s `performBatchUpdates`**. Especialy if you are using some diffing algorithms like [DifferenceKit](https://github.com/ra1028/DifferenceKit).
It is very possible that you are sending delete/insert commands when you expect to see reload. The easiest way to check it is by adding
`print("\(updateItems)")` into `ChatLayout.prepare(forCollectionViewUpdates:)` method. `ChatLayout` doesn't know what you expected to see. 
It just processes your changes according to the commands it has received.

### About sticky headers or footers

Sticky headers or footers are not supported by `ChatLayout` but your contributions are welcome.

## License

`ChatLayout` is distributed under [the MIT license](https://github.com/ekazaev/ChatLayout/blob/master/LICENSE).

`ChatLayout` is provided for your use, free-of-charge, on an as-is basis. We make no guarantees, promises or
apologies. *Caveat developer.*

## Articles

English:
- [My COVID-19 lockdown project or how I started to dig into a custom UICollectionViewLayout to get a ChatLayout](https://eugenenekhoroshiy.medium.com/my-covid-19-lockdown-project-or-how-i-started-to-dig-into-a-custom-uicollectionviewlayout-to-get-a-d053e1ad3aa0)

Russian:
  - [Мой Covid-19 lockdown проект, или, как я полез в кастомный UICollectionViewLayout и получил ChatLayout](https://habr.com/ru/post/523492/)

## Sponsor this project

If you like this library and especially if you are using it in production please consider sponsoring this 
project [here](https://github.com/sponsors/ekazaev). I work on `ChatLayout` in my spare time. Sponsorship 
will help me to work on this project and continue to contribute to the Open Source community.

## Author
  
Evgeny Kazaev, eugene.kazaev@gmail.com. Twitter [ekazaev](https://twitter.com/EKazaev)

*I am happy to answer any questions you may have. Just create a [new issue](https://github.com/ekazaev/ChatLayout/issues/new).*
