Class {
	#name : #SoilSerializer,
	#superclass : #SoilBasicSerializer,
	#instVars : [
		'clusterRoot'
	],
	#category : #'Soil-Serializer-Serializer/Materializer'
}

{ #category : #'instance creation' }
SoilSerializer class >> on: aStream [ 
	^ self new 
		stream: aStream 
]

{ #category : #public }
SoilSerializer class >> serializeToBytes: anObject [ 

	^ (self on: ByteArray new writeStream) 
		serialize: anObject

]

{ #category : #writing }
SoilSerializer >> nextPutArray: anArray [ 
	self 
		nextPutByte: TypeCodeArray;
		nextPutLengthEncodedInteger: anArray size.
	1 to: anArray size do: [:i | 
		(anArray at: i) theNonSoilProxy soilSerialize: self ].
]

{ #category : #writing }
SoilSerializer >> nextPutAssociation: anAssociation [ 
	self nextPutByte: TypeCodeAssociation.
	anAssociation key theNonSoilProxy soilSerialize: self.
	anAssociation value theNonSoilProxy soilSerialize: self.
]

{ #category : #writing }
SoilSerializer >> nextPutClass: aClass [ 

	self 
		nextPutByte: TypeCodeClass; 
		basicNextPutString: aClass name asString
]

{ #category : #writing }
SoilSerializer >> nextPutCompiledBlock: aCompiledMethod [
	
	| bytecodesPlusTrailerSize |
	bytecodesPlusTrailerSize := aCompiledMethod size
	                            - aCompiledMethod initialPC + 1.

	self
		nextPutByte: TypeCodeCompiledBlock;
		nextPutInteger: aCompiledMethod header;
		nextPutLengthEncodedInteger: bytecodesPlusTrailerSize.
	"literals
	Here we have to take care about outer code: just skip it for now (we store clean blocks)
	It is needed for debugging and printing, but not execution"

	1 to: aCompiledMethod numLiterals -1  do: [ :i | 
		(aCompiledMethod literalAt: i) soilSerialize: self ].
	
	"variable part"
	self nextPutBytesFrom: aCompiledMethod bytecodes

]

{ #category : #writing }
SoilSerializer >> nextPutCompiledMethod: aCompiledMethod [

	| bytecodesPlusTrailerSize |
	bytecodesPlusTrailerSize := aCompiledMethod size
	                            - aCompiledMethod initialPC + 1.

	self
		nextPutByte: TypeCodeCompiledMethod;
		nextPutInteger: aCompiledMethod header;
		nextPutLengthEncodedInteger: bytecodesPlusTrailerSize.
	"literals"
	"for now we do store the class pointer in the last literal"
	1 to: aCompiledMethod numLiterals do: [ :i | 
		(aCompiledMethod literalAt: i) soilSerialize: self ].
	"variable part"
	self nextPutBytesFrom: aCompiledMethod bytecodes
	
]

{ #category : #writing }
SoilSerializer >> nextPutDictionary: aDictionary [ 
	self 
		nextPutByte: TypeCodeDictionary;
		nextPutLengthEncodedInteger: aDictionary size.
	aDictionary keysAndValuesDo: [:key :value |
		key theNonSoilProxy soilSerialize: self.
		value theNonSoilProxy soilSerialize: self ]
]

{ #category : #registry }
SoilSerializer >> nextPutExternalReference: anInteger [
	self 
		nextPutByte: TypeCodeExternalReference; 
		nextPutLengthEncodedInteger: anInteger 
]

{ #category : #writing }
SoilSerializer >> nextPutIdentityDictionary: anIdentityDictionary [ 
	self 
		nextPutByte: TypeCodeIdentityDictionary;
		nextPutLengthEncodedInteger: anIdentityDictionary size.
	anIdentityDictionary keysAndValuesDo: [:key :value |
		key theNonSoilProxy soilSerialize: self.
		value theNonSoilProxy soilSerialize: self ]
]

{ #category : #writing }
SoilSerializer >> nextPutInternalReference: anInteger [ 
	self 
		nextPutByte: TypeCodeInternalReference; 
		nextPutLengthEncodedInteger: anInteger 
]

{ #category : #writing }
SoilSerializer >> nextPutMessage: aMessage [ 
	self nextPutByte: TypeCodeMessage.
	aMessage selector soilSerialize: self.
	aMessage arguments soilSerialize: self
]

{ #category : #writing }
SoilSerializer >> nextPutMessageSend: aMessageSend [ 
	self nextPutByte: TypeCodeMessageSend.
	aMessageSend receiver soilSerialize: self.
	aMessageSend selector soilSerialize: self.
	aMessageSend arguments soilSerialize: self
]

{ #category : #writing }
SoilSerializer >> nextPutObjectType [
	self nextPutByte: TypeCodeObject 
]

{ #category : #writing }
SoilSerializer >> nextPutOrderedCollection: aCollection [ 
	self
		nextPutByte: TypeCodeOrderedCollection;
		nextPutLengthEncodedInteger: aCollection size.
	aCollection do: [:each | each theNonSoilProxy soilSerialize: self ].
]

{ #category : #writing }
SoilSerializer >> nextPutPersistentDictionary: aPersistentDictionary [ 
	self 
		nextPutByte: TypeCodePersistentDictionary;
		nextPutLengthEncodedInteger: aPersistentDictionary size.
	aPersistentDictionary keysAndValuesDo: [:key :value |
		key theNonSoilProxy soilSerialize: self.
		value theNonSoilProxy soilSerialize: self ]
]

{ #category : #writing }
SoilSerializer >> nextPutProcessorScheduler: aProcessorScheduler [ 
	self nextPutByte: TypeCodeProcessScheduler 
]

{ #category : #writing }
SoilSerializer >> nextPutSystemDictionary: aCollection [ 
	self nextPutByte: TypeCodeSystemDictionary 
]

{ #category : #writing }
SoilSerializer >> notSupportedError: anObject [ 
	Error signal: 'serialization of class ', anObject class name asString , ' is not supported'
]

{ #category : #registry }
SoilSerializer >> registerIndexedObject: anObject [ 
	"indexes are registered in the segment of the cluster root. So we pass
	the cluster root in order to figure the segment"
	^ transaction 
		registerIndexedObject: anObject 
		forRoot: clusterRoot 
]

{ #category : #registry }
SoilSerializer >> registerObject: anObject ifAbsent: aBlock [
	| index externalIndex |
	objectIdTable ifEmpty: [
		"the cluster root is serialized first so we put it in the object able
		for later references. Above we checked for an empty object table so
		later references to the cluster root will become an internal reference"
		objectIdTable ifEmpty: [ objectIdTable add: anObject ].
		^ aBlock value ].
	index := objectIdTable identityIndexOf: anObject.
	(index > 0) ifTrue: [
		self nextPutInternalReference: index.
		^ self ].
	externalIndex := externalObjectRegistry
		ifNotNil: [ externalObjectRegistry indexOfExternalReference: anObject ]
		ifNil: [
			"if there is no external object repository we cannot
			resolve external objects, hence we treat them as
			internal. This might be too dangerous later and might
			be removed"
			0 ].
	(anObject ~~ clusterRoot and: [ externalIndex > 0 ])
		ifTrue: [
			self nextPutExternalReference: externalIndex ]
		ifFalse: [
			objectIdTable add: anObject.
			aBlock value ]
]

{ #category : #private }
SoilSerializer >> serialize: anObject [
	clusterRoot := anObject.
	clusterRoot soilSerialize: self.
	stream flush.
	^ stream contents
]

{ #category : #public }
SoilSerializer >> serializeBehaviorDescriptionFor: anObject [
	| index |
	index := externalObjectRegistry indexOfBehaviorDescription: anObject class.
	self nextPutObjectType.
	self nextPutLengthEncodedInteger: index.
	^ externalObjectRegistry behaviorDescriptionAt: index
]

{ #category : #public }
SoilSerializer >> serializeToBytes: anObject [ 

	^ (self stream: ByteArray new writeStream) 
		serialize: anObject

]

{ #category : #accessing }
SoilSerializer >> transaction [
	^ transaction 
]
