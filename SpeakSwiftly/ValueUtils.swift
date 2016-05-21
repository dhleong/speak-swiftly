//
//  ValueUtils.swift
//  SpeakSwiftly
//
//  Created by Daniel Leong on 5/14/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Foundation

public func joinAsString(arg: SpeechGrammarObject) -> AnyObject {
    let strings = arg.getChildren()?.map { $0.asValue()! as! String }
    return (strings!).joinWithSeparator("")
}

public func flatJoinAsString(arg: SpeechGrammarObject) -> AnyObject {
    let arrays = arg.getChildren()?.flatMap { (kid) -> [Any] in
        if let value = kid.asValue() {
            if value is String {
                return [value]
            } else {
                return value as! [Any]
            }
        } else {
            return []
        }
    }
    return arrays!.map { $0 as! String }.joinWithSeparator("")
}