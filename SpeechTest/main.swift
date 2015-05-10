//
//  main.swift
//  SpeechTest
//
//  Created by Daniel Leong on 5/7/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Foundation

var recognizer = SpeechRecognizer()

var nato = SGChoice(pickFromStrings: ["alpha", "bravo", "charlie"])
var three = SGPath(path: [nato, nato, nato])
var two = SGPath(path: [nato, nato])
var one = nato
var grammar = SGChoice(pickFrom: [one, two, three])

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