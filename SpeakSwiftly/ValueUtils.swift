//
//  ValueUtils.swift
//  SpeakSwiftly
//
//  Created by Daniel Leong on 5/14/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Foundation

public func joinAsString(arg: SpeechGrammarObject) -> AnyObject {
    var strings = arg.getChildren()?.map { $0.asValue()! as! String }
    return "".join(strings!)
}

public func flatJoinAsString(arg: SpeechGrammarObject) -> AnyObject {
    var arrays = arg.getChildren()?.flatMap { (kid) -> [Any] in
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
    return "".join(arrays!.map { $0 as! String })
}