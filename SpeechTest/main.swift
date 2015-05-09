//
//  main.swift
//  SpeechTest
//
//  Created by Daniel Leong on 5/7/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Foundation

//import Cocoa
//
//class MyDelegate: NSObject, NSSpeechRecognizerDelegate {
//    
//    func speechRecognizer(sender: NSSpeechRecognizer, didRecognizeCommand command: AnyObject?) {
//        NSLog("Hello?")
//        if let thisCommand: AnyObject = command {
//            println("Recognized \(thisCommand)");
//        } else {
//            println("Bummer")
//        }
//    }
//    
//}
//
//
//var delegate = MyDelegate()
//var commands = ["alpha", "bravo", "charlie", "delta", "taxi to runway"]
//
//var recognizer = NSSpeechRecognizer()
//recognizer.commands = commands
//recognizer.delegate = delegate
//
//recognizer.startListening()
//
//println("Hello, World!")
//while (true) {
//    if (false) {
//        print("\(delegate)\r");
//    }
//}


var recognizer = SpeechRecognizer()
recognizer.setGrammar(CommandsGrammar(commands: ["alpha", "bravo", "charlie"]))
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