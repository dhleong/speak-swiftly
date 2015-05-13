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
    
    /// Make a shallow clone of this object whose contents
    ///  match those of the provided obj
    func cloneWithContents(obj: SRLanguageObject) -> SpeechGrammarObject
    
    /// Returns "self" again for convenience
    func setValue(block: (SpeechGrammarObject) -> AnyObject) -> SpeechGrammarObject
    
    func getChildren() -> [SpeechGrammarObject]?
    
    func getTag() -> String?
    
    func release();
    
    /// The "length" of this object, typically in number of words
    ///  along a single path. Mostly for internal use
    func length() -> Int
    
    func withTag(tag: String) -> SpeechGrammarObject
    
    func optionally() -> SGOptional
    
    func then(next: SpeechGrammarObject) -> SGPath
}

public class SGBaseObject {
    
    static var nextId: Int = 0
    
    public let myId: Int
    
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
//    public func setValue<T: SpeechGrammarObject>(block: (SpeechGrammarObject) -> AnyObject) -> T {
    public func setValue(block: (SpeechGrammarObject) -> AnyObject) -> SpeechGrammarObject {
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
    
    public func getTag() -> String? {
        return nil
    }
    
    public func withTag(tag: String) -> SpeechGrammarObject {
        return SGTagged(delegate: self as! SpeechGrammarObject, tag: tag)
    }
    
    private func setSelfRef(languageObj: SRLanguageObject) -> SRLanguageObject {
        var id = myId
        languageObj.setRef(&id)
        return languageObj
    }
}

// Has to be public because Swift is dumb
public class _SGDelegate: SpeechGrammarObject {
    
    public let myId: Int
    
    let delegate: SpeechGrammarObject
    var valueBlock: ((SpeechGrammarObject) -> AnyObject)?
    
    private init(delegate: SpeechGrammarObject) {
        myId = delegate.myId
        
        self.delegate = delegate
    }
    
    // NB: This should be overridden. I would love for this to be
    //   an abstract method, but Swift doesn't support them :/
    public func cloneWithContents(obj: SRLanguageObject) -> SpeechGrammarObject {
        return delegate.cloneWithContents(obj)
    }
    
    public func getChildren() -> [SpeechGrammarObject]? {
        return delegate.getChildren()
    }
    
    public func getTag() -> String? {
        return nil
    }
    
    public func release() {
        delegate.release()
    }
    
    public func asValue() -> Any? {
        
        if let block = valueBlock {
            return block(delegate)
        }
        
        return delegate.asValue()
    }
    
    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        var obj = delegate.asLanguageObject(system)
        var id = myId
        obj.setRef(&id)
        return obj
    }
    
    public func length() -> Int {
        return delegate.length()
    }
    
    public func setValue(block: (SpeechGrammarObject) -> AnyObject) -> SpeechGrammarObject {
        valueBlock = block
        return self
    }
    
    public func withTag(tag: String) -> SpeechGrammarObject {
        return SGTagged(delegate: self, tag: tag)
    }
    
    public func optionally() -> SGOptional {
        return SGOptional(with: self)
    }
    
    public func then(next: SpeechGrammarObject) -> SGPath {
        return SGPath(path: [self, next])
    }
}


public class SGWord: SGBaseObject, SpeechGrammarObject {

    let word: String
    var wordObj: SRWord? = nil
    
    init(from word: String) {
        if let spaces = word.rangeOfString(" ") {
            // Starting recognition with such a word will crash
            //  with GPFLT or something. Luckily, OSX's speech
            //  recognition seems to do pretty okay with the
            //  spaces removed for small words.... Otherwise,
            //  use a phrase
            println("WARNING: SGWords may not contain spaces! (found \(word)); Truncating...")
            self.word = word.stringByReplacingOccurrencesOfString(" ", withString: "")
        } else {
            
            self.word = word
        }
    }
    
    public override func asValue() -> Any? {
        
        if let providedValue = super.asValue() {
            return providedValue
        }
       
        return word
    }
    
    public func cloneWithContents(obj: SRLanguageObject) -> SpeechGrammarObject {
        return self
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
    
    public init(pickFromStrings words: [String]) {
        self.choices = words.map { SGWord(from: $0) }
    }
    
    /// Create a choice between words, whose values will be
    ///  those provided in the dictionary
    public init(pickFromStringsWithValues words: [String:String]) {
        choices = [SpeechGrammarObject]()
        for (word, value) in words {
            choices.append(SGWord(from: word).setValue { _ in value })
        }
    }
    
    /// Create a choice between words, providing a Value function
    ///  that can operate directly on the string
    public convenience init(pickFromStrings words: [String], withValues choiceValueBlock: (String) -> String) {
        self.init(pickFromStrings: words)
        
        for obj in choices {
            obj.setValue({ choiceValueBlock(($0 as! SGWord).word) })
        }
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
    
    public func cloneWithContents(obj: SRLanguageObject) -> SpeechGrammarObject {
        
        if obj.getCount() != 1 {
            // the choice should have been made!
            println("EXPECTED CHOICE SIZE 1 but was \(obj.getCount())!!")
        }
        
        var chosen = obj.getItem(0)
        var chosenId: Int = chosen.getRef()
        for choice in choices {
            if choice.myId == chosenId {
                var clone = SGChoice(pickFrom: [choice.cloneWithContents(chosen)])
                clone.valueBlock = valueBlock
                return clone
            }
        }
        
        // shouldn't happen
        var members = choices.map { $0.myId }
        println("\(obj.getText()) CHOSE \(chosenId) but NOT a member! (\(members))")
        return self
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
        var value = objs.map { $0.asValue() }
                        .filter { $0 != nil } // remove nils
                        .map { $0! } // the remaining are non-nil
        return value.isEmpty ? nil : value
    }
    
    public func cloneWithContents(obj: SRLanguageObject) -> SpeechGrammarObject {
        
        if obj.getCount() != objs.count {
            println("Count mismatch!! \(obj.getCount()) != \(objs.count)")
        }
        
        var shadowPath = [SpeechGrammarObject]()
        for i in 0..<objs.count {
            shadowPath.append(objs[i].cloneWithContents(obj.getItem(i)))
        }
        
        var clone = SGPath(path: shadowPath)
        clone.valueBlock = valueBlock
        return clone
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
    
    private init(clone: SGRepeat, with obj: SRLanguageObject) {
        delegate = clone.delegate.cloneWithContents(obj) as! SGChoice
    }
    
    public override func asValue() -> Any? {
        
        if let providedValue = super.asValue() {
            return providedValue
        }
        
        return delegate.asValue()
    }
    
    public func cloneWithContents(obj: SRLanguageObject) -> SpeechGrammarObject {
        // NB: I have NO idea why it won't let me set valueBlock in the constructor...
        var clone = SGRepeat(clone: self, with: obj)
        clone.valueBlock = valueBlock
        return clone
    }
    
    public func getChildren() -> [SpeechGrammarObject]? {
        return delegate.getChildren()
    }
    
    public func release() {
        delegate.release()
    }
    
    public func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
        return setSelfRef(delegate.asLanguageObject(system))
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
    
    public override func asValue() -> Any? {
        var value = super.asValue()
        if value is [Any] {
            // it should be
            return (value as! [Any]).first
        }
        
        return value
    }
}

// NB: This doesn't seem to work for some reason...
//public class SGOptional: _SGDelegate {
//    init(with obj: SpeechGrammarObject) {
//        super.init(delegate: obj)
//    }
//    
//    public override func cloneWithContents(obj: SRLanguageObject) -> SpeechGrammarObject {
//        var clone = SGOptional(with: delegate.cloneWithContents(obj))
//        clone.valueBlock = valueBlock
//        return clone
//    }
//    
//    public override func asLanguageObject(system: SRRecognitionSystem) -> SRLanguageObject {
//        var obj = super.asLanguageObject(system)
//        var isOptional = Boolean(1)
//        obj.setProperty(kSROptional, value: &isOptional)
//        return obj
//    }
//}

/// Value for SGChoice to represent a null choice
internal class SGEmpty: SGPath {
    
    static let INSTANCE = SGEmpty()
    
    private init() {
        super.init(path: [])
    }
    
    override func asValue() -> Any? {
       return nil
    }
}

public class SGTagged: _SGDelegate {
    
    var tag: String
    
    private init(delegate: SpeechGrammarObject, tag: String) {
        self.tag = tag
        
        super.init(delegate: delegate)
    }
    
    public override func cloneWithContents(obj: SRLanguageObject) -> SpeechGrammarObject {
        var clone = SGTagged(delegate: delegate.cloneWithContents(obj), tag: tag)
        clone.valueBlock = valueBlock
        return clone
    }
    
    public override func getTag() -> String? {
        return tag
    }
    
    public override func withTag(tag: String) -> SpeechGrammarObject {
        self.tag = tag
        return self
    }
}