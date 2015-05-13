//
//  main.swift
//  SpeakSwiftly test
//
//  Created by Daniel Leong on 5/7/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Foundation

func joinAsString(arg: SpeechGrammarObject) -> AnyObject {
    var strings = arg.getChildren()?.map { $0.asValue()! as! String }
    return "".join(strings!)
}

func flatJoinAsString(arg: SpeechGrammarObject) -> AnyObject {
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

var nato = SGChoice(pickFromStrings: ["alpha", "bravo", "charlie"])
for choice in nato.choices {
    var word = (choice as! SGWord)
    word.setValue({ _ in
        word.word.substringToIndex(advance(word.word.startIndex, 1)).uppercaseString
    })
}
nato.setValue(joinAsString)

var number = SGChoice(pickFromStrings: ["zero", "one", "two", "three"])
for index in 0..<number.choices.count {
    var word = number.choices[index] as! SGWord
    word.setValue({ _ in "\(index)" })
}
number.setValue(joinAsString)

var letters = nato.repeated(atMost: 3).setValue(flatJoinAsString)
var name = letters.then(number.optionally()).withTag("name")
                .setValue(flatJoinAsString)
var grammar = SGWord(from: "hello").then(name)

var recognizer = SpeechRecognizer()
recognizer.textDelegate = SpeechTextAdapter(with: { println("Text: `\($0)`") })
recognizer.meaningDelegate = SpeechMeaningAdapter(with: { println("Meanings: \($0)") })
recognizer.setGrammar(grammar)
println("Starting...")

if recognizer.start() {

    println("Started!")

//    while (true) {
//        recognizer.idle()
//        
//        sleep(1)
//    }
    dispatch_main()
} else {
    
    println("Failed to initialize")
}

