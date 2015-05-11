//
//  main.swift
//  SpeakSwiftly test
//
//  Created by Daniel Leong on 5/7/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Foundation

var nato = SGChoice(pickFromStrings: ["alpha", "bravo", "charlie"])
var number = SGChoice(pickFromStrings: ["one", "two", "three"])

func foo(item: SGRepeat) -> AnyObject {
    return 42
}

var name = nato.repeated(atMost: 3)
var grammar = name.then(number.optionally())

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

