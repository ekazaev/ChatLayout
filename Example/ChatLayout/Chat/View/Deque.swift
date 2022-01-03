//
// Created by Eugene Kazaev on 03/01/2022.
// Copyright (c) 2022 CocoaPods. All rights reserved.
//

import Foundation

//MARK: Deque
/// A double-ended queue type. `Deque` is an `Array`-like random-access collection of arbitrary elements
/// that provides efficient insertion and deletion at both ends.
///
/// Like arrays, deques are value types with copy-on-write semantics. `Deque` allocates a single buffer for
/// element storage, using an exponential growth strategy.
///
public struct Deque<Element> {
    /// The storage for this deque.
    internal fileprivate(set) var buffer: DequeBuffer<Element>

    /// Initializes an empty deque.
    public init() {
        buffer = DequeBuffer()
    }

    /// Initializes an empty deque that is able to store at least `minimumCapacity` items without reallocating its storage.
    public init(minimumCapacity: Int) {
        buffer = DequeBuffer(capacity: minimumCapacity)
    }

    /// Initialize a new deque from the elements of any sequence.
    public init<S: Sequence>(_ elements: S) where S.Element == Element {
        self.init(minimumCapacity: elements.underestimatedCount)
        append(contentsOf: elements)
    }

    /// Initialize a deque of `count` elements, each initialized to `repeating`.
    public init(repeating: Element, count: Int) {
        buffer = DequeBuffer(repeating: repeating, count: count)
    }
}

//MARK: Uniqueness and Capacity
extension Deque {
    /// The maximum number of items this deque can store without reallocating its storage.
    ///
    /// If the deque grows larger than its capacity, it discards its current storage and allocates a larger one.
    public var capacity: Int { return buffer.capacity }

    fileprivate func grow(_ capacity: Int) -> Int {
        guard capacity > self.capacity else { return self.capacity }
        return Swift.max(capacity, 2 * self.capacity)
    }

    /// Ensure that this deque is capable of storing at least `minimumCapacity` items without reallocating its storage.
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        guard buffer.capacity < minimumCapacity else { return }
        if isKnownUniquelyReferenced(&buffer) {
            buffer = buffer.realloc(minimumCapacity)
        }
        else {
            let new = DequeBuffer<Element>(capacity: minimumCapacity)
            new.insert(contentsOf: buffer, at: 0)
            buffer = new
        }
    }

    internal var isUnique: Bool { mutating get { return isKnownUniquelyReferenced(&buffer) } }

    @inline(__always)
    fileprivate mutating func makeUnique() {
        self.makeUnique(buffer.capacity)
    }

    @inline(__always)
    fileprivate mutating func makeUnique(_ capacity: Int) {
        guard !isUnique || buffer.capacity < capacity else { return }
        let copy = DequeBuffer<Element>(capacity: capacity)

        // Ensure new buffer is indistinguishable from the original in unit tests.
        // This is a workaround for a compiler issue where the pass-by-reference optimization seems to be missing in debug builds.
        copy.start = buffer.start

        copy.insert(contentsOf: buffer, at: 0)
        buffer = copy
    }
}

//MARK: MutableCollection
extension Deque: RandomAccessCollection, MutableCollection {
    public typealias Index = Int
    public typealias Indices = CountableRange<Int>
    public typealias Iterator = IndexingIterator<Deque<Element>>
    #if swift(>=4.1) || (swift(>=3.3) && !swift(>=4.0))
    public typealias SubSequence = Slice<Deque<Element>>
    #else
    public typealias SubSequence = RangeReplaceableRandomAccessSlice<Deque<Element>>
    #endif

    /// The number of elements currently stored in this deque.
    public var count: Int { return buffer.count }

    /// The indices that are valid for subscripting the collection, in ascending order.
    public var indices: CountableRange<Int> {
        return startIndex ..< endIndex
    }

    /// The position of the first element in a non-empty deque (this is always zero).
    public var startIndex: Int { return 0 }

    /// The index after the last element in a non-empty deque (this is always the element count).
    public var endIndex: Int { return count }

    /// Returns the position immediately after the given index.
    public func index(after index: Int) -> Int {
        return index + 1
    }

    /// Returns the position immediately before the given index.
    public func index(before index: Int) -> Int {
        return index - 1
    }

    /// Returns an index that is the specified distance from the given index.
    public func index(_ i: Int, offsetBy n: Int) -> Index {
        return i + n
    }

    /// Replaces the given index with its successor.
    public func formIndex(after index: inout Int) {
        index += 1
    }

    /// Replaces the given index with its predecessor.
    public func formIndex(before index: inout Int) {
        index -= 1
    }

    /// Offsets the given index by the specified distance.
    ///
    /// Advancing an index beyond a collection's ending index or offsetting it
    /// before a collection's starting index will generate an invalid index.
    ///
    /// - Parameters
    ///   - i: A valid index of the collection.
    ///   - n: The distance to offset `i`.
    ///
    /// - SeeAlso: `index(_:offsetBy:)`, `formIndex(_:offsetBy:limitedBy:)`
    /// - Complexity: O(1)
    public func formIndex(_ i: inout Index, offsetBy n: Int) {
        i += n
    }

    /// `true` iff this deque is empty.
    public var isEmpty: Bool { return count == 0 }

    @inline(__always)
    fileprivate func checkSubscript(_ index: Int) {
        precondition(index >= 0 && index < count)
    }

    // Returns or changes the element at `index`.
    public subscript(index: Int) -> Element {
        get {
            checkSubscript(index)
            return buffer[index]
        }
        set(value) {
            checkSubscript(index)
            makeUnique()
            buffer[index] = value
        }
    }

    /// Accesses a contiguous subrange of the collection’s elements.
    public subscript(bounds: Range<Int>) -> SubSequence {
        get {
            return SubSequence(base: self, bounds: bounds)
        }
        set {
            self.replaceSubrange(bounds, with: newValue)
        }
    }
}

//MARK: ArrayLiteralConvertible
extension Deque: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.buffer = DequeBuffer(capacity: elements.count)
        buffer.insert(contentsOf: elements, at: 0)
    }
}

//MARK: CustomStringConvertible
extension Deque: CustomStringConvertible, CustomDebugStringConvertible {

    private func makeDescription(debug: Bool) -> String {
        var result = debug ? "\(String(reflecting: Deque.self))([" : "Deque["
        var first = true
        for item in self {
            if first {
                first = false
            } else {
                result += ", "
            }
            if debug {
                debugPrint(item, terminator: "", to: &result)
            }
            else {
                print(item, terminator: "", to: &result)
            }
        }
        result += debug ? "])" : "]"
        return result
    }

    public var description: String {
        return makeDescription(debug: false)
    }
    public var debugDescription: String {
        return makeDescription(debug: true)
    }
}

//MARK: RangeReplaceableCollection
extension Deque: RangeReplaceableCollection {
    /// Replace the given `range` of elements with `newElements`.
    ///
    /// - Complexity: O(`range.count`) if storage isn't shared with another live deque,
    ///   and `range` is a constant distance from the start or the end of the deque; otherwise O(`count + range.count`).
    public mutating func replaceSubrange<C: Collection>(_ range: Range<Int>, with newElements: C) where C.Element == Element {
        precondition(range.lowerBound >= 0 && range.upperBound <= count)
        let newCount: Int = numericCast(newElements.count)
        let delta = newCount - range.count
        if isUnique && count + delta <= capacity {
            buffer.replaceSubrange(range, with: newElements)
        }
        else {
            let b = DequeBuffer<Element>(capacity: grow(count + delta))
            b.insert(contentsOf: self.buffer, subrange: 0 ..< range.lowerBound, at: 0)
            b.insert(contentsOf: newElements, at: b.count)
            b.insert(contentsOf: self.buffer, subrange: range.upperBound ..< count, at: b.count)
            buffer = b
        }
    }

    // Code targeting the Swift 4.1 compiler and below
    #if !(swift(>=4.1.50) || (swift(>=3.4) && !swift(>=4.0)))
    public mutating func replaceSubrange<C: Collection>(_ range: CountableRange<Int>, with newElements: C) where C.Element == Element {
        // This is also defined as a protocol extension on RangeReplaceableCollection. However, using that extension
        // breaks isUnique, leading to extra COW copies. Providing this overload restores COW behavior in static contexts, at least.
        self.replaceSubrange(Range(range), with: newElements)
    }
    #endif

    public mutating func replaceSubrange<C: Collection>(_ range: ClosedRange<Int>, with newElements: C) where C.Element == Element {
        // This is also defined as a protocol extension on RangeReplaceableCollection. However, using that extension
        // breaks isUnique, leading to extra COW copies. Providing this overload restores COW behavior in static contexts, at least.
        self.replaceSubrange(Range(range), with: newElements)
    }

    // Code targeting the Swift 4.1 compiler and below
    #if !(swift(>=4.1.50) || (swift(>=3.4) && !swift(>=4.0)))
    public mutating func replaceSubrange<C: Collection>(_ range: CountableClosedRange<Int>, with newElements: C) where C.Element == Element {
        // This is also defined as a protocol extension on RangeReplaceableCollection. However, using that extension
        // breaks isUnique, leading to extra COW copies. Providing this overload restores COW behavior in static contexts, at least.
        self.replaceSubrange(Range(range), with: newElements)
    }
    #endif

    /// Append `newElement` to the end of this deque.
    ///
    /// - Parameter newElement: The element to append to the deque.
    ///
    /// - Complexity: Appending an element to the deque averages to O(1) over
    ///   many additions. When the deque needs to reallocate storage before
    ///   appending or its storage is shared with another copy, appending an
    ///   element is O(*n*), where *n* is the length of the deque.
    public mutating func append(_ newElement: Element) {
        makeUnique(grow(count + 1))
        buffer.append(newElement)
    }

    /// Appends the elements of a sequence to the end of the deque.
    ///
    /// - Parameter newElements: The elements to append to the deque.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the resulting deque.
    public mutating func append<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        makeUnique(self.count + newElements.underestimatedCount)
        var capacity = buffer.capacity
        var count = buffer.count
        var iterator = newElements.makeIterator()
        var next = iterator.next()
        while next != nil {
            if capacity == count {
                reserveCapacity(grow(count + 1))
                capacity = buffer.capacity
            }
            var i = buffer.bufferIndex(forDequeIndex: count)
            let p = buffer.elements
            while let element = next, count < capacity {
                p.advanced(by: i).initialize(to: element)
                i += 1
                if i == capacity { i = 0 }
                count += 1
                next = iterator.next()
            }
            buffer.count = count
        }
    }

    /// Insert `newElement` at index `i` into this deque.
    ///
    /// - Complexity: O(`count`). Note though that complexity is O(1) if `i` is of a constant distance from the front or end of the deque.
    public mutating func insert(_ newElement: Element, at i: Int) {
        makeUnique(grow(count + 1))
        buffer.insert(newElement, at: i)
    }

    /// Insert the contents of `newElements` into this deque, starting at index `i`.
    ///
    /// - Complexity: O(`count`). Note though that complexity is O(1) if `i` is of a constant distance from the front or end of the deque.
    public mutating func insert<C: Collection>(contentsOf newElements: C, at i: Int) where C.Element == Element {
        makeUnique(grow(count + numericCast(newElements.count)))
        buffer.insert(contentsOf: newElements, at: i)
    }

    /// Remove the element at a given index from this deque.
    ///
    /// - Complexity: O(`count`). Note though that complexity is O(1) if `index` is of a constant distance from the front or end of the deque.
    @discardableResult
    public mutating func remove(at index: Int) -> Element {
        checkSubscript(index)
        makeUnique()
        let element = buffer[index]
        buffer.removeSubrange(index ..< index + 1)
        return element
    }

    /// Remove and return the first element from this deque.
    ///
    /// - Requires: `count > 0`
    /// - Complexity: O(1) if storage isn't shared with another live deque; otherwise O(`count`).
    @discardableResult
    public mutating func removeFirst() -> Element {
        precondition(count > 0)
        makeUnique()
        return buffer.popFirst()!
    }

    /// Remove the first `n` elements from this deque.
    ///
    /// - Requires: `count >= n`
    /// - Complexity: O(`n`) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func removeFirst(_ n: Int) {
        precondition(count >= n)
        makeUnique()
        buffer.removeSubrange(0 ..< n)
    }

    /// Remove the first `n` elements from this deque.
    ///
    /// - Requires: `count >= n`
    /// - Complexity: O(`n`) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func removeSubrange(_ range: Range<Int>) {
        precondition(range.lowerBound >= 0 && range.upperBound <= count)
        makeUnique()
        buffer.removeSubrange(range)
    }

    @available(*, deprecated, renamed: "removeAll(keepingCapacity:)")
    public mutating func removeAll(keepCapacity: Bool) {
        self.removeAll(keepingCapacity: keepCapacity)
    }

    /// Remove all elements from this deque.
    ///
    /// - Complexity: O(`count`).
    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        makeUnique()
        if keepCapacity {
            buffer.removeSubrange(0..<count)
        }
        else {
            buffer = DequeBuffer()
        }
    }
}

//MARK: Miscellaneous mutators
extension Deque {
    /// Remove and return the last element from this deque.
    ///
    /// - Requires: `count > 0`
    /// - Complexity: O(1) if storage isn't shared with another live deque; otherwise O(`count`).
    @discardableResult
    public mutating func removeLast() -> Element {
        precondition(count > 0)
        makeUnique()
        return buffer.popLast()!
    }

    /// Remove and return the last `n` elements from this deque.
    ///
    /// - Requires: `count >= n`
    /// - Complexity: O(`n`) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func removeLast(_ n: Int) {
        let c = count
        precondition(c >= n)
        makeUnique()
        buffer.removeSubrange(c - n ..< c)
    }

    /// Remove and return the first element if the deque isn't empty; otherwise return nil.
    ///
    /// - Complexity: O(1) if storage isn't shared with another live deque; otherwise O(`count`).
    @discardableResult
    public mutating func popFirst() -> Element? {
        makeUnique()
        return buffer.popFirst()
    }

    /// Remove and return the last element if the deque isn't empty; otherwise return nil.
    ///
    /// - Complexity: O(1) if storage isn't shared with another live deque; otherwise O(`count`).
    @discardableResult
    public mutating func popLast() -> Element? {
        makeUnique()
        return buffer.popLast()
    }

    /// Prepend `newElement` to the front of this deque.
    ///
    /// - Complexity: Amortized O(1) if storage isn't shared with another live deque; otherwise O(count).
    public mutating func prepend(_ element: Element) {
        makeUnique(grow(count + 1))
        buffer.prepend(element)
    }
}

//MARK: Equality operators
func == <Element: Equatable>(a: Deque<Element>, b: Deque<Element>) -> Bool {
    let count = a.count
    if count != b.count { return false }
    if count == 0 || a.buffer === b.buffer { return true }

    var agen = a.makeIterator()
    var bgen = b.makeIterator()
    while let anext = agen.next() {
        let bnext = bgen.next()
        if anext != bnext { return false }
    }
    return true
}

func != <Element: Equatable>(a: Deque<Element>, b: Deque<Element>) -> Bool {
    return !(a == b)
}

//MARK: DequeBuffer
/// Storage buffer for a deque.
final class DequeBuffer<Element> {
    /// Pointer to allocated storage.
    internal fileprivate(set) var elements: UnsafeMutablePointer<Element>
    /// The capacity of this storage buffer.
    internal let capacity: Int
    /// The number of items currently in this deque.
    internal fileprivate(set) var count: Int
    /// The index of the first item.
    internal fileprivate(set) var start: Int

    internal init(capacity: Int = 16) {
        // TODO: It would be nicer if element storage was tail-allocated after this instance.
        // ManagedBuffer is supposed to do that, but ManagedBuffer is surprisingly slow. :-/
        self.elements = UnsafeMutablePointer.allocate(capacity: capacity)
        self.capacity = capacity
        self.count = 0
        self.start = 0
    }

    internal convenience init(repeating: Element, count: Int) {
        self.init(capacity: count)
        let p = elements
        self.count = count
        var q = p
        let limit = p + count
        while q != limit {
            q.initialize(to: repeating)
            q += 1
        }
    }

    deinit {
        let p = self.elements
        if start + count <= capacity {
            p.advanced(by: start).deinitialize(count: count)
        }
        else {
            let c = capacity - start
            p.advanced(by: start).deinitialize(count: c)
            p.deinitialize(count: count - c)
        }
        #if swift(>=4.1) || (swift(>=3.3) && !swift(>=4.0))
        p.deallocate()
        #else
        p.deallocate(capacity: capacity)
        #endif
    }

    internal func realloc(_ capacity: Int) -> DequeBuffer {
        if capacity <= self.capacity { return self }
        let buffer = DequeBuffer(capacity: capacity)
        buffer.count = self.count
        let dst = buffer.elements
        let src = self.elements
        if self.start + self.count <= self.capacity {
            dst.moveInitialize(from: src.advanced(by: start), count: count)
        }
        else {
            let c = self.capacity - self.start
            dst.moveInitialize(from: src.advanced(by: self.start), count: c)
            dst.advanced(by: c).moveInitialize(from: src, count: self.count - c)
        }
        self.count = 0
        return buffer
    }


    /// Returns the storage buffer index for a deque index.
    internal func bufferIndex(forDequeIndex index: Int) -> Int {
        let i = start + index
        if i >= capacity { return i - capacity }
        if i < 0 { return i + capacity }
        return i
    }

    /// Returns the deque index for a storage buffer index.
    internal func dequeIndex(forBufferIndex i: Int) -> Int {
        if i >= start {
            return i - start
        }
        return capacity - start + i
    }

    internal var isFull: Bool { return count == capacity }

    internal subscript(index: Int) -> Element {
        get {
            assert(index >= 0 && index < count)
            let i = bufferIndex(forDequeIndex: index)
            return elements.advanced(by: i).pointee
        }
        set {
            assert(index >= 0 && index < count)
            let i = bufferIndex(forDequeIndex: index)
            elements.advanced(by: i).pointee = newValue
        }
    }

    internal func prepend(_ element: Element) {
        precondition(count < capacity)
        let i = start == 0 ? capacity - 1 : start - 1
        elements.advanced(by: i).initialize(to: element)
        self.start = i
        self.count += 1
    }

    @discardableResult
    internal func popFirst() -> Element? {
        guard count > 0 else { return nil }
        let first = elements.advanced(by: start).move()
        self.start = bufferIndex(forDequeIndex: 1)
        self.count -= 1
        return first
    }

    internal func append(_ element: Element) {
        precondition(count < capacity)
        let endIndex = bufferIndex(forDequeIndex:count)
        elements.advanced(by: endIndex).initialize(to: element)
        self.count += 1
    }

    @discardableResult
    internal func popLast() -> Element? {
        guard count > 0 else { return nil }
        let lastIndex = bufferIndex(forDequeIndex: count - 1)
        let last = elements.advanced(by: lastIndex).move()
        self.count -= 1
        return last
    }

    /// Create a gap of `length` uninitialized slots starting at `index`.
    /// Existing elements are moved out of the way.
    /// You are expected to fill the gap by initializing all slots in it after calling this method.
    /// Note that all previously calculated buffer indexes are invalidated by this method.
    fileprivate func openGap(at index: Int, length: Int) {
        assert(index >= 0 && index <= self.count)
        assert(count + length <= capacity)
        guard length > 0 else { return }
        let i = bufferIndex(forDequeIndex: index)
        if index >= (count + 1) / 2 {
            // Make room by sliding elements at/after index to the right
            let end = start + count <= capacity ? start + count : start + count - capacity
            if i <= end { // Elements after index are not yet wrapped
                if end + length <= capacity { // Neither gap nor elements after it will be wrapped
                    // ....ABCD̲EF......
                    elements.advanced(by: i + length).moveInitialize(from: elements.advanced(by: i), count: end - i)
                    // ....ABC.̲..DEF...
                }
                else if i + length <= capacity { // Elements after gap will be wrapped
                    // .........ABCD̲EF. (count = 3)
                    elements.moveInitialize(from: elements.advanced(by: capacity - length), count: end + length - capacity)
                    // EF.......ABCD̲...
                    elements.advanced(by: i + length).moveInitialize(from: elements.advanced(by: i), count: capacity - i - length)
                    // EF.......ABC.̲..D
                }
                else { // Gap will be wrapped
                    // .........ABCD̲EF. (count = 5)
                    elements.advanced(by: i + length - capacity).moveInitialize(from: elements.advanced(by: i), count: end - i)
                    // .DEF.....ABC.̲...
                }
            }
            else { // Elements after index are already wrapped
                if i + length <= capacity { // Gap will not be wrapped
                    // F.......ABCD̲E (count = 1)
                    elements.advanced(by: length).moveInitialize(from: elements, count: end)
                    // .F......ABCD̲E
                    elements.moveInitialize(from: elements.advanced(by: capacity - length), count: length)
                    // EF......ABCD̲.
                    elements.advanced(by: i + length).moveInitialize(from: elements.advanced(by: i), count: capacity - i - length)
                    // EF......ABC.̲D
                }
                else { // Gap will be wrapped
                    // F.......ABCD̲E (count = 3)
                    elements.advanced(by: length).moveInitialize(from: elements, count: end)
                    // ...F....ABCD̲E
                    elements.advanced(by: i + length - capacity).moveInitialize(from: elements.advanced(by: i), count: capacity - i)
                    // .DEF....ABC.̲.
                }
            }
            count += length
        }
        else {
            // Make room by sliding elements before index to the left, updating `start`.
            if i >= start { // Elements before index are not yet wrapped.
                if start >= length { // Neither gap nor elements before it will be wrapped.
                    // ....ABCD̲EF...
                    elements.advanced(by: start - length).moveInitialize(from: elements.advanced(by: start), count: i - start)
                    // .ABC...D̲EF...
                }
                else if i >= length { // Elements before the gap will be wrapped.
                    // ..ABCD̲EF....
                    elements.advanced(by: capacity + start - length).moveInitialize(from: elements.advanced(by: start), count: length - start)
                    // ...BCD̲EF...A
                    elements.moveInitialize(from: elements.advanced(by: length), count: i - length)
                    // BC...D̲EF...A
                }
                else { // Gap will be wrapped
                    // .ABCD̲EF....... (count = 5)
                    elements.advanced(by: capacity + start - length).moveInitialize(from: elements.advanced(by: start), count: i - start)
                    // ....D̲EF...ABC.
                }
            }
            else { // Elements before index are already wrapped.
                if i >= length { // Gap will not be wrapped.
                    // BCD̲EF......A (count = 1)
                    elements.advanced(by: start - length).moveInitialize(from: elements.advanced(by: start), count: capacity - start)
                    // BCD̲EF.....A.
                    elements.advanced(by: capacity - length).moveInitialize(from: elements, count: length)
                    // .CD̲EF.....AB
                    elements.moveInitialize(from: elements.advanced(by: i - length), count: i - length)
                    // C.D̲EF.....AB
                }
                else { // Gap will be wrapped.
                    // CD̲EF......AB
                    elements.advanced(by: start - length).moveInitialize(from: elements.advanced(by: start), count: capacity - start)
                    // CD̲EF...AB...
                    elements.advanced(by: capacity - length).moveInitialize(from: elements, count: i)
                    // .D̲EF...ABC..
                }
            }
            start = start < length ? capacity + start - length : start - length
            count += length
        }
    }

    internal func insert(_ element: Element, at index: Int) {
        precondition(index >= 0 && index <= count && !isFull)
        openGap(at: index, length: 1)
        let i = bufferIndex(forDequeIndex: index)
        elements.advanced(by: i).initialize(to: element)
    }

    internal func insert(contentsOf buffer: DequeBuffer, at index: Int) {
        self.insert(contentsOf: buffer, subrange: 0 ..< buffer.count, at: index)
    }

    internal func insert(contentsOf buffer: DequeBuffer, subrange: Range<Int>, at index: Int) {
        assert(buffer !== self)
        assert(index >= 0 && index <= count)
        assert(count + subrange.count <= capacity)
        assert(subrange.lowerBound >= 0 && subrange.upperBound <= buffer.count)
        guard subrange.count > 0 else { return }
        openGap(at:
        index, length: subrange.count)

        let dp = self.elements
        let sp = buffer.elements

        let dstStart = self.bufferIndex(forDequeIndex: index)
        let srcStart = buffer.bufferIndex(forDequeIndex: subrange.lowerBound)

        let srcCount = subrange.count

        let dstEnd = self.bufferIndex(forDequeIndex: index + srcCount)
        let srcEnd = buffer.bufferIndex(forDequeIndex: subrange.upperBound)

        if srcStart < srcEnd && dstStart < dstEnd {
            dp.advanced(by: dstStart).initialize(from: sp.advanced(by: srcStart), count: srcCount)
        }
        else if dstStart < dstEnd {
            let t = buffer.capacity - srcStart
            dp.advanced(by: dstStart).initialize(from: sp.advanced(by: srcStart), count: t)
            dp.advanced(by: dstStart + t).initialize(from: sp, count: srcCount - t)
        }
        else if srcStart < srcEnd {
            let t = self.capacity - dstStart
            dp.advanced(by: dstStart).initialize(from: sp.advanced(by: srcStart), count: t)
            dp.initialize(from: sp.advanced(by: srcStart + t), count: srcCount - t)
        }
        else {
            let st = buffer.capacity - srcStart
            let dt = self.capacity - dstStart

            if dt < st {
                dp.advanced(by: dstStart).initialize(from: sp.advanced(by: srcStart), count: dt)
                dp.initialize(from: sp.advanced(by: srcStart + dt), count: st - dt)
                dp.advanced(by: st - dt).initialize(from: sp, count: srcCount - st)
            }
            else if dt > st {
                dp.advanced(by: dstStart).initialize(from: sp.advanced(by: srcStart), count: st)
                dp.advanced(by: dstStart + st).initialize(from: sp, count: dt - st)
                dp.initialize(from: sp.advanced(by: dt - st), count: srcCount - dt)
            }
            else {
                dp.advanced(by: dstStart).initialize(from: sp.advanced(by: srcStart), count: st)
                dp.initialize(from: sp, count: srcCount - st)
            }
        }
    }

    internal func insert<C: Collection>(contentsOf collection: C, at index: Int) where C.Element == Element {
        assert(index >= 0 && index <= count)
        let c: Int = numericCast(collection.count)
        assert(count + c <= capacity)
        guard c > 0 else { return }
        openGap(at: index, length: c)
        var q = elements.advanced(by: bufferIndex(forDequeIndex: index))
        let limit = elements.advanced(by: capacity)
        for element in collection {
            q.initialize(to: element)
            q = q.successor()
            if q == limit {
                q = elements
            }
        }
    }

    /// Destroy elements in the range (index ..< index + count) and collapse the gap by moving remaining elements.
    /// Note that all previously calculated buffer indexes are invalidated by this method.
    fileprivate func removeSubrange(_ range: Range<Int>) {
        assert(range.lowerBound >= 0)
        assert(range.upperBound <= self.count)
        guard range.count > 0 else { return }
        let rc = range.count
        let p = elements
        let i = bufferIndex(forDequeIndex: range.lowerBound)
        let j = i + rc <= capacity ? i + rc : i + rc - capacity

        // Destroy items in collapsed range
        if i <= j {
            // ....ABC̲D̲E̲FG...
            p.advanced(by: i).deinitialize(count: rc)
            // ....AB...FG...
        }
        else {
            // D̲E̲FG.......ABC̲
            p.advanced(by: i).deinitialize(count: capacity - i)
            // D̲E̲FG.......AB.
            p.deinitialize(count: j)
            // ..FG.......AB.
        }

        if count - range.lowerBound - rc < range.lowerBound {
            let end = start + count < capacity ? start + count : start + count - capacity

            // Slide trailing items to the left
            if i <= end { // No wrap anywhere after start of collapsed range
                // ....AB.̲..CD...
                p.advanced(by: i).moveInitialize(from: p.advanced(by: i + rc), count: end - i - rc)
                // ....ABC̲D......
            }
            else if i + rc > capacity { // Collapsed range is wrapped
                if end <= rc { // Result will not be wrapped
                    // .CD......AB.̲..
                    p.advanced(by: i).moveInitialize(from: p.advanced(by: i + rc - capacity), count: capacity + end - i - rc)
                    // .........ABC̲D.
                }
                else { // Result will remain wrapped
                    // .CDEFG...AB.̲..
                    p.advanced(by: i).moveInitialize(from: p.advanced(by: i + rc - capacity), count: capacity - i)
                    // ....FG...ABC̲DE
                    p.moveInitialize(from: p.advanced(by: rc), count: end - rc)
                    // FG.......ABC̲DE
                }
            }
            else { // Wrap is after collapsed range
                if end <= rc { // Result will not be wrapped
                    // D.......AB.̲..C
                    p.advanced(by: i).moveInitialize(from: p.advanced(by: i + rc), count: capacity - i - rc)
                    // D.......ABC̲...
                    p.advanced(by: capacity - rc).moveInitialize(from: p, count: end)
                    // ........ABC̲D..
                }
                else { // Result will remain wrapped
                    // DEFG....AB.̲..C
                    p.advanced(by: i).moveInitialize(from: p.advanced(by: i + rc), count: capacity - i - rc)
                    // DEFG....ABC̲...
                    p.advanced(by: capacity - rc).moveInitialize(from: p, count: rc)
                    // ...G....ABC̲DEF
                    p.moveInitialize(from: p.advanced(by: rc), count: end - rc)
                    // G.......ABC̲DEF
                }
            }
            count -= rc
        }
        else {
            // Slide preceding items to the right
            if j >= start { // No wrap anywhere before end of collapsed range
                // ...AB...C̲D...
                p.advanced(by: start + rc).moveInitialize(from: p.advanced(by: start), count: j - start - rc)
                // ......ABC̲D...
            }
            else if j < rc { // Collapsed range is wrapped
                if  start + rc >= capacity  { // Result will not be wrapped
                    // ...C̲D.....AB..
                    p.advanced(by: start + rc - capacity).moveInitialize(from: p.advanced(by: start), count: capacity + j - start - rc)
                    // .ABC̲D.........
                }
                else { // Result will remain wrapped
                    // ..E̲F.....ABCD..
                    p.moveInitialize(from: p.advanced(by: capacity - rc), count: j)
                    // CDE̲F.....AB....
                    p.advanced(by: start + rc).moveInitialize(from: p.advanced(by: start), count: capacity - start - rc)
                    // CDE̲F.........AB
                }
            }
            else { // Wrap is before collapsed range
                if capacity - start <= rc { // Result will not be wrapped
                    // CD...E̲F.....AB
                    p.advanced(by: rc).moveInitialize(from: p, count: j - rc)
                    // ...CDE̲F.....AB
                    p.advanced(by: start + rc - capacity).moveInitialize(from: p.advanced(by: start), count: capacity - start)
                    // .ABCDE̲F.......
                }
                else { // Result will remain wrapped
                    // EF...G̲H...ABCD
                    p.advanced(by: rc).moveInitialize(from: p, count: j - rc)
                    // ...EFG̲H...ABCD
                    p.moveInitialize(from: p.advanced(by: capacity) - rc, count: rc)
                    // BCDEFG̲H...A...
                    p.advanced(by: start + rc).moveInitialize(from: p.advanced(by: start), count: capacity - start - rc)
                    // BCDEFG̲H......A
                }
            }
            start = (start + rc < capacity ? start + rc : start + rc - capacity)
            count -= rc
        }
    }

    internal func replaceSubrange<C: Collection>(_ range: Range<Int>, with newElements: C) where C.Element == Element {
        let newCount: Int = numericCast(newElements.count)
        let delta = newCount - range.count
        assert(count + delta < capacity)
        let common = min(range.count, newCount)
        if common > 0 {
            let p = elements
            var q = p.advanced(by: bufferIndex(forDequeIndex: range.lowerBound))
            let limit = p.advanced(by: capacity)
            var i = common
            for element in newElements {
                q.pointee = element
                q = q.successor()
                if q == limit { q = p }
                i -= 1
                if i == 0 { break }
            }
        }
        if range.count > common {
            removeSubrange(range.lowerBound + common ..< range.upperBound)
        }
        else if newCount > common {
            openGap(at: range.lowerBound + common, length: newCount - common)
            let p = elements
            var q = p.advanced(by: bufferIndex(forDequeIndex: range.lowerBound + common))
            let limit = p.advanced(by: capacity)
            var i = newElements.index(newElements.startIndex, offsetBy: numericCast(common))
            while i != newElements.endIndex {
                q.initialize(to: newElements[i])
                newElements.formIndex(after: &i)
                q = q.successor()
                if q == limit { q = p }
            }
        }
    }
}

//MARK:
extension DequeBuffer {
    internal func forEach(_ body: (Element) throws -> ()) rethrows {
        if start + count <= capacity {
            var p = elements + start
            for _ in 0 ..< count {
                try body(p.pointee)
                p += 1
            }
        }
        else {
            var p = elements + start
            for _ in start ..< capacity {
                try body(p.pointee)
                p += 1
            }
            p = elements
            for _ in 0 ..< start + count - capacity {
                try body(p.pointee)
                p += 1
            }
        }
    }
}

extension Deque {
    public func forEach(_ body: (Element) throws -> ()) rethrows {
        try withExtendedLifetime(buffer) { buffer in
            try buffer.forEach(body)
        }
    }

    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        var result: [T] = []
        result.reserveCapacity(self.count)
        try self.forEach { result.append(try transform($0)) }
        return result
    }

    public func flatMap<T>(_ transform: (Element) throws -> T?) rethrows -> [T] {
        var result: [T] = []
        try self.forEach {
            if let r = try transform($0) {
                result.append(r)
            }
        }
        return result
    }

    public func flatMap<S: Sequence>(_ transform: (Element) throws -> S) rethrows -> [S.Element] {
        var result: [S.Element] = []
        try self.forEach {
            result.append(contentsOf: try transform($0))
        }
        return result
    }

    public func filter(_ includeElement: (Element) throws -> Bool) rethrows -> [Element] {
        var result: [Element] = []
        try self.forEach {
            if try includeElement($0) {
                result.append($0)
            }
        }
        return result
    }

    public func reduce<T>(_ initial: T, combine: (T, Element) throws -> T) rethrows -> T {
        var result = initial
        try self.forEach {
            result = try combine(result, $0)
        }
        return result
    }
}