Class {
	#name : #SoilBasicMaterializer,
	#superclass : #SoilObjectCodec,
	#instVars : [
		'objects'
	],
	#category : #'Soil-Serializer-Serializer/Materializer'
}

{ #category : #'reading - basic' }
SoilBasicMaterializer >> basicNextString [
	| string length |
	string := String new: (length := self nextLengthEncodedInteger).
	stream readInto: string startingAt: 1 count: length.
	^ string
]

{ #category : #initialization }
SoilBasicMaterializer >> initialize [ 
	super initialize.
	objects := OrderedCollection new
]

{ #category : #'reading - basic' }
SoilBasicMaterializer >> nextByte [
	^ stream next
]

{ #category : #reading }
SoilBasicMaterializer >> nextByteArray: aClass [ 
	| byteArray size |
	byteArray := aClass new: (size := self nextLengthEncodedInteger).
	self registerObject: byteArray.
	stream readInto: byteArray startingAt: 1 count: size.
	^ byteArray
]

{ #category : #reading }
SoilBasicMaterializer >> nextByteCharacter [
	"call to #register: not needed as character is an immediate Object"
	^ Character codePoint: self nextByte
]

{ #category : #reading }
SoilBasicMaterializer >> nextCharacter [
	"call to #register: not needed as character is an immediate Object"
	^ Character value: self nextLengthEncodedInteger
]

{ #category : #reading }
SoilBasicMaterializer >> nextDate: aClass [ 
	| date |
	date := aClass 
		julianDayNumber: 2415386 + self nextSoilObject 
		offset: (Duration minutes: self nextSoilObject).
	self registerObject: date.
	^ date
]

{ #category : #reading }
SoilBasicMaterializer >> nextFloat: aClass [ 
	"We multiply the Boxedfloat by 1, this way we create a SmallFloat if possible"
	| float |
	float :=  BoxedFloat64 basicNew
		  at: 1 put: self nextLengthEncodedInteger;
		  at: 2 put: self nextLengthEncodedInteger;
		  * 1.
	"Boxedfloat is a normal object (needs to be registered), SmallFloat is immediate"
	float isImmediateObject ifFalse: [self registerObject: float].
	^float
]

{ #category : #reading }
SoilBasicMaterializer >> nextFraction: aClass [
	| fraction |
	fraction := aClass
		numerator: self nextLengthEncodedInteger
		denominator: self nextLengthEncodedInteger.
	self registerObject: fraction.
	^ fraction
]

{ #category : #reading }
SoilBasicMaterializer >> nextLargeNegativeInteger [
	| integer |
	"Large Integers are normal objects (need to be registered), small integers are immediate"
	integer := 0 - self nextLengthEncodedInteger.
	integer isImmediateObject ifFalse: [ self registerObject: integer].
	^integer
]

{ #category : #reading }
SoilBasicMaterializer >> nextLargePositiveInteger [
	| integer |
	integer := self nextLengthEncodedInteger.
	integer isImmediateObject ifFalse: [ self registerObject: integer].
	^integer
]

{ #category : #'reading - basic' }
SoilBasicMaterializer >> nextLengthEncodedInteger [
	| value |
	value := self nextByte.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]

{ #category : #reading }
SoilBasicMaterializer >> nextScaledDecimal: aClass [

	| scaledDecimal |
	scaledDecimal := aClass new
		                 setNumerator: self nextLengthEncodedInteger
		                 denominator: self nextLengthEncodedInteger
		                 scale: self nextLengthEncodedInteger.
	self registerObject: scaledDecimal.
	^ scaledDecimal
]

{ #category : #reading }
SoilBasicMaterializer >> nextString [
	| string |
	string := self basicNextString.
	self registerObject: string.
	^ string

]

{ #category : #reading }
SoilBasicMaterializer >> nextSymbol [
	| bytes length |
	length := self nextLengthEncodedInteger.
	bytes := ByteArray new: length.
	stream readInto: bytes startingAt: 1 count: length.
	^ bytes asString asSymbol
	

]

{ #category : #reading }
SoilBasicMaterializer >> nextTime [
	| time |
	time := Time fromSeconds: self nextLengthEncodedInteger.
	self registerObject: time.
	^ time
]

{ #category : #reading }
SoilBasicMaterializer >> nextWideString [
	| buf length wideString |
	buf := ByteArray new: (length := self nextLengthEncodedInteger).
	stream readInto: buf startingAt: 1 count: length.
	wideString := self class decodeBytes: buf. 
	self registerObject: wideString. 
	^ wideString
]

{ #category : #reading }
SoilBasicMaterializer >> nextWideSymbol [
	| buf len |
	buf := ByteArray new: (len := self nextLengthEncodedInteger).
	stream readInto: buf startingAt: 1 count: len.
	^ (self class decodeBytes: buf) asSymbol
]
