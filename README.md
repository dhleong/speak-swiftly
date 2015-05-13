SpeakSwiftly
============

*Tell your computer what to do*

## What?

SpeakSwiftly is an experimental, grammar-based speech recognition framework for 
OSX. It sits atop the Carbon API and provides a simple, DSL-like interface for
creating grammars. Parts of the grammars may be annotated for extracting meaning
from the resulting grammars in a composable way.

*SpeakSwiftly is highly experimental, and the interfaces may change with any commit*

### Usage Example

```swift
/*
 * Build a grammar
 */
var airline = SGChoice(pickFromStringsWithValues: [
    "speedbird": "BAW",
    "united": "UAL",
    "cactus": "AWE",
    "aircanada": "ACA",
    "cessna": "N"
    ])

// (some) nato phonetic numbers
var nato = SGChoice(pickFromStrings: ["alpha", "bravo", "charlie"], withValues: {
    $0.substringToIndex(advance($0.startIndex, 1)).uppercaseString
})
nato.setValue(joinAsString)

// (some) numbers
var number = SGChoice(pickFromStringsWithValues: [
    "zero": "0", "one": "1", "two": "2", "three": "3"])
number.setValue(joinAsString)

//  EG: N241AB, BAW2451
//  The airline may be omitted if unambiguous after initial contact
var numbers = number.repeated(atLeast: 3, atMost: 4).setValue(flatJoinAsString)
var letters = nato.repeated(atLeast: 0, atMost: 2).setValue(flatJoinAsString)
var name = airline.optionally().then(numbers).then(letters)
            .withTag("name") // we'll be able to extract the name using this tag
            .setValue(flatJoinAsString)

// just to prove tag extraction is real, add some words
var grammar = SGWord(from: "hello").then(name)
```

```swift
/*
 * Attach your delegates
 */
var recognizer = SpeechRecognizer()
recognizer.textDelegate = SpeechTextAdapter(with: { 
    /*
     * If you just want the text, it's quite easy to get
     */
    println("Text: `\($0)`") 
})
recognizer.meaningDelegate = SpeechMeaningAdapter(with: { 
    /*
     * The meaning delegate gives you a dictionary
     *  containing the values of matched tags
     */
    var name = $0["name"]
    println("Found name:: \(name)") 
})

// go!
recognizer.setGrammar(grammar)
recognizer.start()
```

#### Utilities

These may get merged into the library proper at some point

```swift
/// Convert a Choice whose values are strings (all of ours are)
///  into a String
func joinAsString(arg: SpeechGrammarObject) -> AnyObject {
    var strings = arg.getChildren()?.map { $0.asValue()! as! String }
    return "".join(strings!)
}

/// Convert a Repeat or a Path whose values may be arrays of
///  Strings, into an array
func flatJoinAsString(arg: SpeechGrammarObject) -> AnyObject {
    var arrays = arg.getChildren()?.flatMap { (kid) -> [Any] in
        if let value = kid.asValue() {
            if value is String {
                return [value]
            } else {
                return value as! [Any]
            }
        } else {
            return []
        }
    }
    return "".join(arrays!.map { $0 as! String })
}

```

