//
//  SpeechGrammar.swift
//  SpeechTest
//
//  Created by Daniel Leong on 5/8/15.
//  Copyright (c) 2015 Daniel Leong. All rights reserved.
//

import Carbon
import Foundation


public protocol SpeechGrammarObject {
    
    func release();
    
    func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject;
}

public protocol SpeechGrammar: SpeechGrammarObject {
    
    func asLanguageModel(system: SRRecognitionSystem) -> SRLanguageModel;
   
}

public class SGWord: SpeechGrammarObject {
    static var id: Int = 0
    
    // TODO support user-provided refcon...
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
}

/// Choose between provided Grammar Objects
public class SGChoice: SpeechGrammarObject, SpeechGrammar {
    
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
        return asLanguageModel(system)
    }
    
    public func asLanguageModel(system: SRRecognitionSystem) -> SRLanguageModel {
        SRNewLanguageModel(system, &model!, "Words", 5)
        
        if let model = self.model {
            var number = 42; // NB bogus values for testing purposes...
            SRSetProperty(model, OSType(kSRRefCon), &number, sizeof(Int))
            
            var index = 0
            for word in choices {
                SRAddLanguageObject(model, word.asLanguageObject(system))
            }
        }
        
        return model!
    }
}

/// A sequence of Grammar Objects
public class SGPath: SpeechGrammar {
    
    var objs: [SpeechGrammarObject]
    var model: SRLanguageModel? = SRLanguageModel()
    var path: SRPath? = SRPath()
    
    init(path objs: [SpeechGrammarObject]) {
        self.objs = objs
    }
    
    public func release() {
        if let obj = self.path {
            SRReleaseObject(obj)
        }
        if let obj = self.model {
            SRReleaseObject(obj)
        }
        
        for obj in objs {
            obj.release()
        }
    }
    
    public func asLanguageModel(system: SRRecognitionSystem) -> SRLanguageModel {
        SRNewLanguageModel(system, &model!, "String", 6)
        SRAddLanguageObject(model!, asLanguageObject(system))
        return model!
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

}
