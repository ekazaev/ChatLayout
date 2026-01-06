//
// ChatLayout
// RandomAccessCollection+Extension.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2026.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

extension RandomAccessCollection where Index == Int {
    func binarySearch(_ predicate: (Element) throws -> ComparisonResult) rethrows -> Index? {
        var lowerBound = startIndex
        var upperBound = endIndex

        while lowerBound < upperBound {
            let midIndex = lowerBound &+ (upperBound &- lowerBound) / 2
            let result = try predicate(self[midIndex])
            if result == .orderedSame {
                return midIndex
            } else if result == .orderedAscending {
                lowerBound = midIndex &+ 1
            } else {
                upperBound = midIndex
            }
        }
        return nil
    }

    func lowerBound(_ predicate: (Element) throws -> Bool) rethrows -> Index? {
        var lower = startIndex
        var upper = endIndex

        while lower < upper {
            let mid = lower &+ (upper &- lower) / 2
            if try predicate(self[mid]) {
                upper = mid
            } else {
                lower = mid &+ 1
            }
        }

        return lower < endIndex ? lower : nil
    }

    func binarySearchRange(_ predicate: (Element) throws -> ComparisonResult) rethrows -> [Element] {
        var lower = startIndex
        var upper = endIndex
        while lower < upper {
            let mid = lower + (upper - lower) / 2
            if try predicate(self[mid]) == .orderedAscending {
                lower = mid + 1
            } else {
                upper = mid
            }
        }
        let start = lower

        lower = start
        upper = endIndex
        while lower < upper {
            let mid = lower + (upper - lower) / 2
            let result = try predicate(self[mid])
            if result == .orderedDescending {
                upper = mid
            } else {
                lower = mid + 1
            }
        }
        let end = lower

        return Array(self[start..<end])
    }
}
