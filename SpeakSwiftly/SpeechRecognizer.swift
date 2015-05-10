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

public protocol SpeechRecognizerDelegate {
    func onRecognition()
}

public class SpeechRecognizer {
    public var delegate: SpeechRecognizerDelegate?
    
    // obj-c / swift callback bridging
    var bridgeBlock: COpaquePointer?
    var appleEventCallback: AEEventHandlerUPP?
    
    var system: SRRecognitionSystem = SRRecognitionSystem();
    var recognizer: SRRecognizer = SRRecognizer();
    var grammar: SpeechGrammar?;

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

            println("EVENT! \(theAEevent) status=\(recognitionStatus)")
            self.handleResult2(speechResult)
            SRReleaseObject(speechResult)
            return OSErr(0)
        }
        
        bridgeBlock = imp_implementationWithBlock(unsafeBitCast(appleBridge, AnyObject.self))
        appleEventCallback = unsafeBitCast(bridgeBlock!, AEEventHandlerUPP.self)
    }
    
    deinit {
        imp_removeBlock(bridgeBlock!)
    }
    
    func handleResult(result: SRRecognitionResult) {
        println("result = \(result)")
        var modelPtr = UnsafeMutablePointer<SRLanguageModel>.alloc(1)
        var size: Int = sizeof(UnsafePointer<SRLanguageModel>)
        var theErr = SRGetProperty(result, OSType(kSRLanguageModelFormat), modelPtr, &size)
        if OSStatus(theErr) != noErr {
            println("GetLang ERROR = \(theErr)")
            return
        }
        
        var model = modelPtr.memory
        processResult(model)
        
        SRReleaseObject(model)
        modelPtr.destroy()
    }

    func processResult(model: SRLanguageModel) {
//        
//        var itemsCount = -1;
//        var theErr = SRCountItems(model, &itemsCount)
//        if OSStatus(theErr) != noErr {
//            println("err: \(theErr)")
//            return;
//        }
//        if (itemsCount <= 0) {
//            println("No items in the result model \(itemsCount)")
//            return;
//        } else {
//            println("FOUND \(itemsCount) items!")
//        }

////        var object: SRLanguageObject = SRLanguageObject()
//        var objectPtr = UnsafeMutablePointer<SRLanguageObject>.alloc(1)
//        SRGetIndexedItem(model, objectPtr, 0)
//        var object = objectPtr.memory
        
        var refCon = 0
        var size = sizeof(Int)
        var type = OSType(kSRRefCon)
        
        println("model=\(model); type=\(type)")
        SRGetProperty(model, type, &refCon, &size)
        
        println("model=\(model); ref=\(refCon)")
        
//        objectPtr.destroy()
    }

    func handleResult2(result: SRRecognitionResult) {
    
        var resultStr = [CChar](count: MAX_RECOGNITION_LENGTH, repeatedValue: 0)
        resultStr.withUnsafeMutableBufferPointer { (inout buffer: UnsafeMutableBufferPointer<CChar>) -> () in
                
            var resultStrLen = MAX_RECOGNITION_LENGTH
            SRGetProperty(result, OSType(kSRTEXTFormat), buffer.baseAddress, &resultStrLen)
        }
        
        var result = String.fromCString(resultStr)
        println("Done! \(result)")
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
        
        SRReleaseObject(recognizer)
        SRCloseRecognitionSystem(system)
        
        if let grammar = self.grammar {
            grammar.release()
        }
        
        started = false;
    }
}
