//
//  main.swift
//  SpeakSwiftly test
//
//  Created by Daniel Leong on 5/7/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Foundation
import SpeakSwiftly


var airline = SGChoice(pickFromStringsWithValues: [
    "speedbird": "BAW",
    "united": "UAL",
    "cactus": "AWE",
    "aircanada": "ACA",
    "cessna": "N"
    ])

var nato = SGChoice(pickFromStrings: ["alpha", "bravo", "charlie", "delta", "echo",
    "foxtrot", "golf", "hotel", "india", "juliett", "kilo", "lima", "mike",
    "november", "oscar", "papa", "quebec", "romeo", "sierra", "tango",
    "uniform", "victor", "whiskey", "xray", "yankee", "zulu"], withValues: {
    $0.substringToIndex($0.startIndex.advancedBy(1)).uppercaseString
})
nato.setValue(joinAsString)

var number = SGChoice(pickFromStringsWithValues: [
    "zero": "0",
    "one": "1", "two": "2", "three": "3",
    "four": "4", "five": "5", "six": "6",
    "seven": "7", "eight": "8", "niner": "9"])
number.setValue(joinAsString)

var numbers = number.repeated(3, atMost: 4).setValue(flatJoinAsString)
var letters = nato.repeated(exactly: 2).setValue(flatJoinAsString)
var name = airline.optionally().then(numbers).then(letters.optionally())
            .withTag("name")
            .setValue(flatJoinAsString)
var greeting = SGChoice(between:[
    // NB: there's a convenience for word choices (shown above), but you an also
    //  specify your own branches with objects, as well:
    SGWord(from: "hello"),
    SGWord(from: "goodbye"),
    SGPath(from: "whats up")])
    .withTag("greeting")
    .setValue(flatJoinAsString)
var grammar = greeting .then(name)

var recognizer = SpeechRecognizer()
recognizer.textDelegate = SpeechTextAdapter(with: { print("Text: `\($0)`") })
recognizer.meaningDelegate = SpeechMeaningAdapter(with: { print("Meanings: \($0)") })
recognizer.setGrammar(grammar)
print("Starting...")

if recognizer.start() {

    print("Started!")

//    while (true) {
//        recognizer.idle()
//        
//        sleep(1)
//    }
    dispatch_main()
} else {
    
    print("Failed to initialize")
}

