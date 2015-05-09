//
//  SpeechRecognizer.swift
//  SpeechTest
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
    
    /// The queue on which callbacks will be fired
    public lazy var dispatchQueue: dispatch_queue_t = {
        dispatch_get_main_queue()
    }()
   
    // obj-c / swift callback bridging
    var bridgeBlock: COpaquePointer?
    var callback: SRCallBackUPP?
    var callbackParam: SRCallBackParam?
    
    var system: SRRecognitionSystem = SRRecognitionSystem();
    var recognizer: SRRecognizer = SRRecognizer();
    var grammar: SpeechGrammar?;

    var started = false
    
    public init() {

        // see: http://stackoverflow.com/a/29375116
        var bridge : @objc_block (UnsafeMutablePointer<SRCallBackStruct>) -> Void =
        { (callbackStructPtr) in
            let callbackStruct = callbackStructPtr.memory
            self.speechCallback(callbackStruct)
        }
        bridgeBlock = imp_implementationWithBlock(unsafeBitCast(bridge, AnyObject.self))
        let ptr = unsafeBitCast(bridgeBlock!, SRCallBackProcPtr.self)
        let callback = NewSRCallBackUPP(ptr)
        self.callback = callback
        
        callbackParam = SRCallBackParam(callBack: callback, refCon: nil)
    }

    deinit {
        imp_removeBlock(bridgeBlock!)
        DisposeSRCallBackUPP(callback!)
    }
    
    func speechCallback(callback: SRCallBackStruct) {
        println("Callback! what=\(callback.what); message=\(callback.message); status=\(callback.status)")
        if OSStatus(callback.status) != noErr {
            println("Callback ERROR!")
        }
        
        switch (Int(callback.what)) {
        case kSRNotifyRecognitionDone:
            var resultPtr: UnsafePointer<SRRecognitionResult> =
                unsafeBitCast(callback.message, UnsafePointer<SRRecognitionResult>.self)
            var result = resultPtr.memory
            
            // as requested by the docs, we dispatch to another thread for processing
            dispatch_async(dispatchQueue) {
                self.handleResult(result)
                SRReleaseObject(result)
            }
            break;
        default:
            println("Huh")
        }
        
    }

    func handleResult(result: SRRecognitionResult) {
        var model: SRLanguageModel = SRLanguageModel()
        var size: Int = sizeof(UnsafePointer<SRLanguageModel>)
        var theErr = SRGetProperty(result, OSType(kSRLanguageModelFormat), &model, &size)
        if OSStatus(theErr) != noErr {
            println("GetLang ERROR = \(theErr)")
            return
        }
        
        processResult(model)
        
        SRReleaseObject(model)
    }

    func processResult(model: SRLanguageModel) {
        
        var refCon = 0
        var size = sizeof(Int)
        var type = OSType(kSRRefCon)
        
        println("model=\(model); type=\(type)")
        SRGetProperty(model, type, &refCon, &size)
        
        println("model=\(model); ref=\(refCon)")
    }

    func handleResult2(result: SRRecognitionResult) {
        
//            var resultStr: [CChar] = []
//            resultStr.reserveCapacity(MAX_RECOGNITION_LENGTH)
            var resultStr = [CChar](count: MAX_RECOGNITION_LENGTH, repeatedValue: 0)
//            resultStr.withUnsafeMutableBufferPointer { (buffer) in
//                var resultStrLen = 0
//    //            println("ptr->\(resultStrPtr) :: \(resultStrLen)")
//                SRGetProperty(result, OSType(kSRTEXTFormat), &resultStr, &resultStrLen)
//            }
            resultStr.withUnsafeMutableBufferPointer { (inout buffer: UnsafeMutableBufferPointer<CChar>) -> () in
                    
                var resultStrLen = MAX_RECOGNITION_LENGTH
    //            println("ptr->\(resultStrPtr) :: \(resultStrLen)")
                SRGetProperty(result, OSType(kSRTEXTFormat), &resultStr, &resultStrLen)
                println("Done! \(buffer)")
            }
            
            
////            var resultStrPtr = UnsafeMutablePointer<[CChar]>(resultStr)
////            var resultStrPtr = &resultStr[0]
////            var resultStrLen = UnsafeMutablePointer<Int>.alloc(1)
//            var resultStrLen = 0
////            println("ptr->\(resultStrPtr) :: \(resultStrLen)")
//            SRGetProperty(result, OSType(kSRTEXTFormat), &resultStr, &resultStrLen)
////            println("Recognition done! \(resultStrPtr.memory)")
            println("Done! \(resultStr)")
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
        var size = sizeof(UnsafePointer<Void>)
        theErr = SRSetProperty(recognizer, OSType(kSRCallBackParam), &callbackParam, size)
        if OSStatus(theErr) != noErr {
            stop()
            return false
        }
        
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