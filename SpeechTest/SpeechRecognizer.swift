//
//  SpeechRecognizer.swift
//  SpeechTest
//
//  Created by Daniel Leong on 5/8/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Carbon
import Foundation

public protocol SpeechRecognizerDelegate {
    func onRecognition()
}

public class SpeechRecognizer {
    public var delegate: SpeechRecognizerDelegate?
    
    var callbackParam: SRCallBackParam?
    
    var system: SRRecognitionSystem = SRRecognitionSystem();
    var recognizer: SRRecognizer = SRRecognizer();
    var grammar: SpeechGrammar?;

    var started = false
    
    public init() {
        // see: http://stackoverflow.com/a/29375116
        var bridge : @objc_block (UnsafeMutablePointer<SRCallBackStruct>) -> Void =
        { (callbackStruct) in
            println("BRIDGE!")
            self.speechCallback(callbackStruct)
        }
        let imp: COpaquePointer = imp_implementationWithBlock(unsafeBitCast(bridge, AnyObject.self))
        let callback: SRCallBackUPP = unsafeBitCast(imp, SRCallBackUPP.self)
        callbackParam = SRCallBackParam(callBack: callback, refCon: nil)
    }
    
    func speechCallback(callback: UnsafeMutablePointer<SRCallBackStruct>) {
        println("Callback! \(callback)")
    }
    
    public func setGrammar(grammar: SpeechGrammar) -> Bool {
        if (started) {
            return false;
        }
        
        self.grammar = grammar
        return true
    }

    public func start() -> Bool {
        
        if (started) {
            return false;
        }
        
        var theErr = SROpenRecognitionSystem(&system, OSType(kSRDefaultRecognitionSystemID));
        if OSStatus(theErr) != noErr {
            return false
        }
        
        theErr = SRNewRecognizer(system, &recognizer, OSType(kSRDefaultSpeechSource));
        if OSStatus(theErr) != noErr {
            stop()
            return false
        }
        
        if let gram = grammar {
            SRSetLanguageModel(recognizer, gram.asLanguageModel(system))
        } else {
            stop()
            return false
        }
        
        // TODO attach listeners
        theErr = SRSetProperty(recognizer, OSType(kSRCallBackParam), &callbackParam, 4)
        if OSStatus(theErr) != noErr {
            stop()
            return false
        }

        SRStartListening(recognizer)

        started = true;
        return true
    }
    
    public func idle() {
        SRIdle()
    }
    
    public func stop() {
        
        if (started) {
            SRStopListening(recognizer)
        }
        
        SRReleaseObject(recognizer)
        SRCloseRecognitionSystem(system)
        
        if let grammar = self.grammar {
            grammar.release()
        }
        
        started = false;
    }
}