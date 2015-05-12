//
//  main.swift
//  SpeakSwiftly test
//
//  Created by Daniel Leong on 5/7/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Foundation

var nato = SGChoice(pickFromStrings: ["alpha", "bravo", "charlie"])
for choice in nato.choices {
    var word = (choice as! SGWord)
    word.withValue({ _ in
        word.word.substringToIndex(advance(word.word.startIndex, 1)).uppercaseString
    })
}

var number = SGChoice(pickFromStrings: ["zero", "one", "two", "three"])
for index in 0..<number.choices.count {
    var word = number.choices[index] as! SGWord
    word.withValue({ _ in "\(index)" })
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

