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

var airline = SGChoice(pickFromStringsWithValues: [
    "speedbird": "BAW",
    "united": "UAL",
    "cactus": "AWE",
    "aircanada": "ACA",
    "cessna": "N"
    ])

var nato = SGChoice(pickFromStrings: ["alpha", "bravo", "charlie"], withValues: {
    $0.substringToIndex(advance($0.startIndex, 1)).uppercaseString
})
nato.setValue(joinAsString)

var number = SGChoice(pickFromStringsWithValues: [
    "zero": "0",
    "one": "1", "two": "2", "three": "3",
    "four": "4", "five": "5", "six": "6",
    "seven": "7", "eight": "8", "niner": "9"])
number.setValue(joinAsString)

//var letters = nato.repeated(atMost: 3).setValue(flatJoinAsString)
//var name = letters.then(number.optionally()).withTag("name")
//                .setValue(flatJoinAsString)
var numbers = number.repeated(atLeast: 3, atMost: 4).setValue(flatJoinAsString)
var letters = nato.repeated(exactly: 2).setValue(flatJoinAsString)
var name = airline.optionally().then(numbers).then(letters.optionally())
            .withTag("name")
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

