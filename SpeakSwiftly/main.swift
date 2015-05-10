//
//  main.swift
//  SpeakSwiftly test
//
//  Created by Daniel Leong on 5/7/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Foundation

var recognizer = SpeechRecognizer()

var nato = SGChoice(pickFromStrings: ["alpha", "bravo", "charlie"])
var number = SGChoice(pickFromStrings: ["one", "two", "three"])

var name = SGRepeat(repeat: nato, atMost: 3)
var grammar = SGPath(path: [name, SGOptional(with: number)])

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
