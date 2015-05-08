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

public class SGWords: SpeechGrammarObject {
    
    var words: [String]
    var model: SRLanguageModel? = SRLanguageModel()
    
    init(words: [String]) {
        self.words = words
    }
    
    public func release() {
        if let model = self.model {
            SRReleaseObject(model)
        }
    }
    
    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        SRNewLanguageModel(system, &model!, "Words", 5)
        
        if let model = self.model {
            for word in words {
                var wordObj: SRWord = SRWord();
                SRNewWord(system, &wordObj, word, Int32(count(word)))
                
                SRAddLanguageObject(model, wordObj)
            }
        }
        
        return model!
    }
}

public class CommandsGrammar: SpeechGrammar {
    
    var words: SGWords
    
    init(commands: [String]) {
        words = SGWords(words: commands)
    }
    
    public func release() {
        words.release()
    }
    
    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        return asLanguageModel(system)
    }
    
    public func asLanguageModel(system: SRRecognitionSystem) -> SRLanguageModel {
        return words.asLanguageObject(system)
    }
}