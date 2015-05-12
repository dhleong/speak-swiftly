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
    
    /// A unique Int id for this object
    var myId: Int { get }
    
    func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject;
    
    func asValue() -> Any?
    
    func getChildren() -> [SpeechGrammarObject]?
    
    func release();
    
    /// The "length" of this object, typically in number of words
    ///  along a single path. Mostly for internal use
    func length() -> Int
}

public class SGBaseObject {
    
    static var nextId: Int = 0
    
    public var myId: Int
    
    var valueBlock: ((SpeechGrammarObject) -> AnyObject)?
    
    private init() {
        myId = SGBaseObject.nextId++
    }
    
    public func asValue() -> Any? {
        if let block = valueBlock {
            return block(self as! SpeechGrammarObject)
        }
        
        return nil
    }
    
    // would love for this to be properly generic, but Swift's generics SUCK.
    //  I would have to make all the subclasses also be generic, which just
    //  doesn't make any sense at all. 
    //  Also, I never thought I'd miss Java's type erasure
//    public func withValue<T: SpeechGrammarObject>(block: (SpeechGrammarObject) -> AnyObject) -> T {
    public func withValue(block: (SpeechGrammarObject) -> AnyObject) -> SpeechGrammarObject {
        valueBlock = block
        return self as! SpeechGrammarObject
    }
    
    /// Wrap this Object so that it's "Optional"
    public func optionally() -> SGOptional {
        return SGOptional(with: self as! SpeechGrammarObject)
    }
    
    /// Wrap this Object in a Repeat for the provided range
    public func repeated(atLeast: Int = 1, atMost: Int) -> SGRepeat {
        return SGRepeat(repeat: self as! SpeechGrammarObject, atLeast: atLeast, atMost: atMost)
    }
    
    /// Wrap this Object in a Repeat for exactly the number of times provided
    public func repeated(exactly times: Int) -> SGRepeat {
        return SGRepeat(repeat: self as! SpeechGrammarObject, atLeast: times, atMost: times)
    }
    
    /// Create a Path starting with `self` then proceeding to `next`
    public func then(next: SpeechGrammarObject) -> SGPath {
        return SGPath(path: [self as! SpeechGrammarObject, next])
    }
    
    private func setSelfRef(languageObj: SRLanguageObject) {
        languageObj.setRef(&myId)
    }
}

public class SGWord: SGBaseObject, SpeechGrammarObject {

    let word: String
    var wordObj: SRWord? = nil
    
    init(from word: String) {
        self.word = word
    }
    
    public override func asValue() -> Any? {
        
        if let providedValue = super.asValue() {
            return providedValue
        }
       
        return word
    }
    
    public func getChildren() -> [SpeechGrammarObject]? {
        return nil
    }
    
    public func release() {
        if let obj = wordObj {
            obj.release()
        }
    }
    
    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        if let wordObj = self.wordObj {
            return wordObj
        }
        
        var myId = self.myId

        var obj = SRWord()
        SRNewWord(system, &obj, word, Int32(count(word)))
        setSelfRef(obj)
        self.wordObj = obj
        return obj
    }
    
    public func length() -> Int {
        return 1
    }
}

/// Choose between provided Grammar Objects
public class SGChoice: SGBaseObject, SpeechGrammarObject {
    
    var choices: [SpeechGrammarObject]
    var model: SRLanguageModel? = nil
    
    init(pickFromStrings words: [String]) {
        self.choices = words.map { SGWord(from: $0) }
    }
    
    init(pickFrom words: [SpeechGrammarObject]) {
        self.choices = words
    }
    
    public override func asValue() -> Any? {
        
        if let providedValue = super.asValue() {
            return providedValue
        }
       
        // There should only be one item when we get the value
        return choices[0].asValue()
    }
    
    public func addChoice(item: SpeechGrammarObject) {
        choices.append(item)
    }
    
    public func getChildren() -> [SpeechGrammarObject]? {
        return choices
    }
    
    public func release() {
        if let model = self.model {
            model.release()
        }
        
        for word in choices {
            word.release()
        }
    }
    
    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        
        if let model = self.model {
            return model
        }
        
        var newModel = SRLanguageModel()
        SRNewLanguageModel(system, &newModel, "Choice", 6)
        setSelfRef(newModel)
        
        // sort the objects before adding---order is important!
        //  longer phrases MUST be before shorter ones for the
        //  system to recognize them
        choices.sort() { $0.length() > $1.length() }
        
        for word in choices {
            SRAddLanguageObject(newModel, word.asLanguageObject(system))
        }
        
        self.model = newModel
        return newModel
    }
    
    public func length() -> Int {
        // the length of a Choice is the length of its longest choice
        return choices.reduce(0) {
            max($0, $1.length())
        }
    }
}

/// A sequence of Grammar Objects
public class SGPath: SGBaseObject, SpeechGrammarObject {
    
    var objs: [SpeechGrammarObject]
    var path: SRPath? = nil
    
    init(path objs: [SpeechGrammarObject]) {
        self.objs = objs
    }
    
    public override func asValue() -> Any? {
        
        if let providedValue = super.asValue() {
            return providedValue
        }
       
        // There should only be one item when we get the value
        return objs.map { $0.asValue() }
    }
    
    public func getChildren() -> [SpeechGrammarObject]? {
        return objs
    }
    
    /// When already a Path, this simply appends and returns itself.
    ///  This lets you do things like `word.then(anotherWord).then(lastWord)`
    override public func then(next: SpeechGrammarObject) -> SGPath {
        objs.append(next)
        return self
    }
    
    public func release() {
        if let obj = self.path {
            obj.release()
        }
        
        for obj in objs {
            obj.release()
        }
    }

    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        if let path = self.path {
            return path
        }
        
        var newPath = SRPath()
        SRNewPath(system, &newPath)
        setSelfRef(newPath)
        
        for obj in objs {
            SRAddLanguageObject(newPath, obj.asLanguageObject(system))
        }

        self.path = newPath
        return newPath
    }

    public func length() -> Int {
        return objs.count
    }
}

/// Repeat the given object some number of times
public class SGRepeat: SGBaseObject, SpeechGrammarObject {
    
    let delegate: SGChoice
    
    init(repeat: SpeechGrammarObject, atLeast rawMin: Int = 1, atMost max: Int) {
        delegate = SGChoice(pickFrom: [])

        var min = rawMin
        if min == 0 {
            delegate.addChoice(SGEmpty.INSTANCE)
            min++
        }
        
        for i in min...max {
            var repeated = SGPath(path: [SpeechGrammarObject](count: i, repeatedValue: repeat))
            delegate.addChoice(repeated)
        }
    }
    
    public override func asValue() -> Any? {
        
        if let providedValue = super.asValue() {
            return providedValue
        }
        
        return delegate.asValue()
    }
    
    public func getChildren() -> [SpeechGrammarObject]? {
        return delegate.getChildren()
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
    
    static let INSTANCE = SGEmpty()
    
    private init() {
        super.init(path: [])
    }
}