//
// ChatLayout
// NSMutableAttributedString+Extensions.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import UIKit

internal extension NSMutableAttributedString {

    @discardableResult
    func bold(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize, textColor: UIColor = .black) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: AnyObject] = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor: textColor
        ]
        let boldString = NSMutableAttributedString(string: text, attributes: attrs)
        append(boldString)
        return self
    }

    @discardableResult
    func medium(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize, textColor: UIColor = .black) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: AnyObject] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.medium),
            NSAttributedString.Key.foregroundColor: textColor
        ]
        let mediumString = NSMutableAttributedString(string: text, attributes: attrs)
        append(mediumString)
        return self
    }

    @discardableResult
    func italic(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize, textColor: UIColor = .black) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: AnyObject] = [
            NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor: textColor
        ]
        let italicString = NSMutableAttributedString(string: text, attributes: attrs)
        append(italicString)
        return self
    }

    @discardableResult
    func normal(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize, textColor: UIColor = .black) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: AnyObject] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor: textColor
        ]
        let normal = NSMutableAttributedString(string: text, attributes: attrs)
        append(normal)
        return self
    }

}

internal extension NSAttributedString {

    func replacingCharacters(in range: NSRange, with attributedString: NSAttributedString) -> NSMutableAttributedString {
        let ns = NSMutableAttributedString(attributedString: self)
        ns.replaceCharacters(in: range, with: attributedString)
        return ns
    }

    static func += (lhs: inout NSAttributedString, rhs: NSAttributedString) {
        let ns = NSMutableAttributedString(attributedString: lhs)
        ns.append(rhs)
        lhs = ns
    }

    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let ns = NSMutableAttributedString(attributedString: lhs)
        ns.append(rhs)
        return NSAttributedString(attributedString: ns)
    }

}
