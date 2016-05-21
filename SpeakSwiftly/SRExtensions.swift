//
//  SRExtensions.swift
//  SpeakSwiftly
//
//  Created by Daniel Leong on 5/11/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Carbon
import Foundation

/// Extensions to the SRLanguageObject for convenience
extension SRLanguageObject {
    
    func getRef<T>() -> T {
        let ptr = UnsafeMutablePointer<T>.alloc(1)
        var size = sizeof(UnsafeMutablePointer<T>)
        getProperty(kSRRefCon, result: ptr, resultSize: &size)
        let result = ptr.memory
        ptr.dealloc(1)
        return result
    }
    
    func getStringProperty(propertyTag: Int) -> String? {
        
        var resultStr = [CChar](count: MAX_RECOGNITION_LENGTH, repeatedValue: 0)
        resultStr.withUnsafeMutableBufferPointer { (inout buffer: UnsafeMutableBufferPointer<CChar>) -> () in
                
            var resultStrLen = MAX_RECOGNITION_LENGTH
            self.getProperty(kSRTEXTFormat, result: buffer.baseAddress, resultSize: &resultStrLen)
        }
        
        return String.fromCString(resultStr)
    }
    
    func getText() -> String? {
        return getStringProperty(kSRTEXTFormat)
    }
    
    func getProperty<T>(propertyTag: Int, result: UnsafeMutablePointer<T>, inout resultSize size: Int) -> OSErr {
        return SRGetProperty(self, OSType(propertyTag), result, &size)
    }
    
    func release() {
        SRReleaseObject(self)
    }
    
    func setRef(ptr: UnsafePointer<Void>) -> OSErr {
        return setProperty(kSRRefCon, value: ptr)
    }
    
    func setProperty(propertyTag: Int, value ptr: UnsafePointer<Void>) -> OSErr {
        let result = SRSetProperty(self, OSType(propertyTag), ptr, sizeof(UnsafePointer<Void>))
        if OSStatus(result) != noErr {
            print("WARN: Error setting property \(propertyTag) on \(self): \(result)")
        }
        return result
    }
}

extension SRSpeechObject {
    /// Returns -1 on error
    func getCount() -> Int {
        var count = -1
        SRCountItems(self, &count)
        return count
    }
    
    /// As with other Get calls from the SR namespace,
    //   you should call .release() on the resulting
    //   object from this call
    func getItem(index: Int) -> SRSpeechObject {
        var object: SRSpeechObject = nil
        SRGetIndexedItem(self, &object, index)
        return object
    }
}