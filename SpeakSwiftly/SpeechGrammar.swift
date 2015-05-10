//
//  SpeechGrammar.swift
//  SpeakSwiftly
//
//  Created by Daniel Leong on 5/8/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Carbon
import Foundation


public protocol SpeechGrammarObject {
    
    func release();
    
    func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject;
    
    /// The "length" of this object, typically in number of words
    ///  along a single path. Mostly for internal use
    func length() -> Int
}

public class SGWord: SpeechGrammarObject {
    static var id: Int = 0
    
    // TODO support user-provided refcon...?
    let myId: Int = id++
    let word: String
    var wordObj: SRWord? = SRWord()
    
    init(from word: String) {
        self.word = word
    }
    
    public func release() {
        if let obj = wordObj {
            SRReleaseObject(obj)
        }
    }
    
    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        var myId = self.myId
        SRNewWord(system, &wordObj!, word, Int32(count(word)))
        SRSetProperty(wordObj!, OSType(kSRRefCon), &myId, sizeof(Int))
        return wordObj!
    }
    
    public func length() -> Int {
        return 1
    }
}

/// Choose between provided Grammar Objects
public class SGChoice: SpeechGrammarObject {
    
    var choices: [SpeechGrammarObject]
    var model: SRLanguageModel? = SRLanguageModel()
    
    init(pickFromStrings words: [String]) {
        self.choices = words.map { SGWord(from: $0) }
    }
    
    init(pickFrom words: [SpeechGrammarObject]) {
        self.choices = words
    }
    
    public func addChoice(item: SpeechGrammarObject) {
        choices.append(item)
    }
    
    public func release() {
        if let model = self.model {
            SRReleaseObject(model)
        }
        
        for word in choices {
            word.release()
        }
    }
    
    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        SRNewLanguageModel(system, &model!, "Choice", 6)
        
        if let model = self.model {
            var number = 42; // NB bogus values for testing purposes...
            SRSetProperty(model, OSType(kSRRefCon), &number, sizeof(Int))
            
            // sort the objects before adding---order is important!
            //  longer phrases MUST be before shorter ones for the
            //  system to recognize them
            choices.sort() { $0.length() > $1.length() }
            
            for word in choices {
                SRAddLanguageObject(model, word.asLanguageObject(system))
            }
        }
        
        return model!
    }
    
    public func length() -> Int {
        // the length of a Choice is the length of its longest choice
        return choices.reduce(0) {
            max($0, $1.length())
        }
    }
}

/// A sequence of Grammar Objects
public class SGPath: SpeechGrammarObject {
    
    var objs: [SpeechGrammarObject]
    var path: SRPath? = SRPath()
    
    init(path objs: [SpeechGrammarObject]) {
        self.objs = objs
    }
    
    public func release() {
        if let obj = self.path {
            SRReleaseObject(obj)
        }
        
        for obj in objs {
            obj.release()
        }
    }

    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        SRNewPath(system, &path!)
        
        if let path = self.path {
            for obj in objs {
                SRAddLanguageObject(path, obj.asLanguageObject(system))
            }
        }

        return path!
    }

    public func length() -> Int {
        return objs.count
    }
}

/// Repeat the given object some number of times
public class SGRepeat: SpeechGrammarObject {
    
    let delegate: SGChoice
    
    init(repeat: SpeechGrammarObject, atLeast rawMin: Int = 1, atMost max: Int) {
        delegate = SGChoice(pickFrom: [])

        var min = rawMin
        if min == 0 {
            delegate.addChoice(SGEmpty())
            min++
        }
        
        for i in min...max {
            var repeated = SGPath(path: [SpeechGrammarObject](count: i, repeatedValue: repeat))
            delegate.addChoice(repeated)
        }
    }
    
    public func release() {
        delegate.release()
    }
    
    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        return delegate.asLanguageObject(system)
    }
    
    public func length() -> Int {
        return delegate.length()
    }
}

/// Convenience for an object that may or may not be present
public class SGOptional: SGRepeat {
    init(with obj: SpeechGrammarObject) {
        super.init(repeat: obj, atLeast: 0, atMost: 1)
    }
}

/// Value for SGChoice to represent a null choice
internal class SGEmpty: SGPath {
    init() {
        super.init(path: [])
    }
}