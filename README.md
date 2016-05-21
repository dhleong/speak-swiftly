SpeakSwiftly [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
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
    $0.substringToIndex($0.startIndex.advancedBy(1)).uppercaseString
})
nato.setValue(joinAsString) // this utility is provided by SpeakSwiftly

// (some) numbers
let number = SGChoice(pickFromStringsWithValues: [
    "zero": "0", "one": "1", "two": "2", "three": "3"])
number.setValue(joinAsString)

//  EG: N241AB, BAW2451
//  The airline may be omitted if unambiguous after initial contact
let numbers = number.repeated(3, atMost: 4).setValue(flatJoinAsString)
let letters = nato.repeated(exactly: 2).setValue(flatJoinAsString)
let name = airline.optionally().then(numbers).then(letters.optionally())
            .withTag("name") // we'll be able to extract the name using this tag
            .setValue(flatJoinAsString) // this is also provided by SpeakSwiftly

// just to prove tag extraction is real, add some words
let grammar = SGWord(from: "hello").then(name)
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
