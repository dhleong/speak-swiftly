//
//  SpeechRecognizer.swift
//  SpeakSwiftly
//
//  Created by Daniel Leong on 5/8/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Carbon
import Foundation

let MAX_RECOGNITION_LENGTH = 255

public protocol SpeechTextRecognizerDelegate {
    func onRecognition(text: String)
}
public protocol SpeechMeaningRecognizerDelegate {
    func onRecognition(meanings: [String:AnyObject])
}

/// Convenience
public class SpeechTextAdapter: SpeechTextRecognizerDelegate {
    var closure: (String) -> ()
    
    init(with closure: (String) -> ()) {
        self.closure = closure
    }
    
    public func onRecognition(text: String) {
        closure(text)
    }
}

/// Convenience
public class SpeechMeaningAdapter: SpeechMeaningRecognizerDelegate {
    var closure: ([String:AnyObject]) -> ()
    
    init(with closure: ([String:AnyObject]) -> ()) {
        self.closure = closure
    }
    
    public func onRecognition(meanings: [String : AnyObject]) {
        closure(meanings)
    }
}

public class SpeechRecognizer {
    public var textDelegate: SpeechTextRecognizerDelegate?
    public var meaningDelegate: SpeechMeaningRecognizerDelegate?
    
    // obj-c / swift callback bridging
    var bridgeBlock: COpaquePointer?
    var appleEventCallback: AEEventHandlerUPP?
    
    var system: SRRecognitionSystem = SRRecognitionSystem();
    var recognizer: SRRecognizer = SRRecognizer();
    var grammar: SpeechGrammarObject?;

    var started = false
    
    public init() {

        // see: http://stackoverflow.com/a/29375116
        var appleBridge: @objc_block (AppleEventPtr, AppleEventPtr, Int) -> OSErr =
        { (theAEevent, reply, refcon) in
            
            var actualType: DescType = DescType()
            var recognitionStatus: OSErr = OSErr(0)
            var actualSize = 0;
            
            var theErr = AEGetParamPtr(theAEevent, OSType(keySRSpeechStatus),
                DescType(typeSInt16), // typeShortInteger
                &actualType,
                &recognitionStatus, sizeof(UnsafePointer<OSErr>),
                &actualSize);
            if OSStatus(theErr) != noErr {
                println("Error getting speech status: \(theErr)")
                return theErr
            }
            if OSStatus(recognitionStatus) != noErr {
                println("Speech recognition error: \(recognitionStatus)")
                return recognitionStatus
            }
            
            var speechResult: SRRecognitionResult = SRRecognitionResult()
            actualSize = 0
            theErr = AEGetParamPtr(theAEevent, OSType(keySRSpeechResult),
                DescType(typeSRSpeechResult), &actualType,
                &speechResult, sizeof(UnsafePointer<SRRecognitionResult>),
                &actualSize)
            if OSStatus(theErr) != noErr {
                println("Error getting recognition result: \(theErr)")
                return theErr
            }

            if let textDelegate = self.textDelegate {
                self.processResultText(speechResult, delegate: textDelegate)
            }
            if let meaningDelegate = self.meaningDelegate {
                self.handleResult(speechResult, delegate: meaningDelegate)
            }
            
            speechResult.release()
            return OSErr(0)
        }
        
        bridgeBlock = imp_implementationWithBlock(unsafeBitCast(appleBridge, AnyObject.self))
        appleEventCallback = unsafeBitCast(bridgeBlock!, AEEventHandlerUPP.self)
    }
    
    deinit {
        imp_removeBlock(bridgeBlock!)
    }
    
    func handleResult(result: SRRecognitionResult, delegate: SpeechMeaningRecognizerDelegate) {
        var modelPtr = UnsafeMutablePointer<SRLanguageModel>.alloc(1)
        var size: Int = sizeof(UnsafePointer<SRLanguageModel>)
        var theErr = result.getProperty(kSRLanguageModelFormat, result: modelPtr, resultSize: &size)
        if OSStatus(theErr) != noErr {
            println("GetLang ERROR = \(theErr)")
            return
        }
        
        var model = modelPtr.memory
        processResultModel(model, delegate: delegate)
        
        model.release()
        modelPtr.destroy()
    }

    func processResultModel(model: SRSpeechObject, delegate: SpeechMeaningRecognizerDelegate) {
//        dive(model, delegate: delegate, depth: 0)
        var grammarRoot: Int = model.getRef()
        
        // TODO construct a shadow tree from the returned Object
        //  that follows the grammar's structure

        
        println("GrammarRoot=\(grammarRoot)")
    }
    
    func dive(model: SRSpeechObject, delegate: SpeechMeaningRecognizerDelegate, depth: Int) {
        var itemsCount = model.getCount()
        if (itemsCount <= 0) {
            println("No items in the result model \(itemsCount)")
            return;
        } else {
            println("FOUND \(itemsCount) items!")
        }

        var refCon: Int = model.getRef()
        println("model=\(model); .size=\(itemsCount); ref=\(refCon)")
        
        for i in 0..<itemsCount {
            var object = model.getItem(i)
            var refCon: Int = object.getRef()
            var str = object.getText()
            println("\(depth)..[\(i)] = \(refCon) (\(str))")
            dive(object, delegate: delegate, depth: (depth + 1))
            
            object.release()
        }
        
    }

    func processResultText(result: SRRecognitionResult, delegate: SpeechTextRecognizerDelegate) {
    
        if let string = result.getText() {
            delegate.onRecognition(string)
        }
        
    }
    
    public func setGrammar(grammar: SpeechGrammarObject) -> Bool {
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
        
        if let grammar = self.grammar {
            SRSetLanguageModel(recognizer, grammar.asLanguageObject(system))
        } else {
            stop()
            return false
        }

        // attach listeners
        AEInstallEventHandler(AEEventClass(kAESpeechSuite), AEEventID(kAESpeechDone),
            appleEventCallback!, nil, Boolean(0))

        var modes = kSRHasFeedbackHasListenModes
        
        theErr = SRSetProperty(system,
            OSType(kSRFeedbackAndListeningModes), &modes,
            sizeof(UnsafePointer<Int>));
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
        
        AERemoveEventHandler(AEEventClass(kAESpeechSuite), AEEventID(kAESpeechDone),
            appleEventCallback!, Boolean(0))
        
        if (started) {
            SRStopListening(recognizer)
        }
        
        recognizer.release()
        SRCloseRecognitionSystem(system)
        
        if let grammar = self.grammar {
            grammar.release()
        }
        
        started = false;
    }

}
