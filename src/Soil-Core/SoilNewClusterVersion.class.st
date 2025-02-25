Class {
	#name : #SoilNewClusterVersion,
	#superclass : #SoilClusterRecord,
	#instVars : [
		'externalObjects',
		'previousVersionRecord',
		'position'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SoilNewClusterVersion >> addObject: anObject reference: anObjectId [
	externalObjects add: anObject.
	self addReference: anObjectId
]

{ #category : #converting }
SoilNewClusterVersion >> asJournalEntry [
	| objectEntry entries |
	entries := OrderedCollection new.
	objectEntry := self hasPreviousVersion 
		ifTrue: [ 
			SoilNewObjectVersionEntry new
				oldBytes: previousVersionRecord bytes ]
		ifFalse: [ SoilNewObjectEntry new ].
	objectEntry 
		record: self;
		objectId: objectId;
		bytes: self serialize.
	entries add: objectEntry.

	object journalEntries do: [ :each | entries add: each ].
	
	^ entries
]

{ #category : #converting }
SoilNewClusterVersion >> asNewClusterVersion [
	^ self
]

{ #category : #converting }
SoilNewClusterVersion >> asPersistentClusterVersion [
	^ SoilPersistentClusterVersion new
		transaction: transaction;
		position: position;
		previousVersionPosition: previousVersionPosition;
		objectId: objectId;
		object: object;
		version: version;
		bytes: bytes
		
		 
]

{ #category : #'as yet unclassified' }
SoilNewClusterVersion >> beChanged [
	"nothing to be done"
]

{ #category : #testing }
SoilNewClusterVersion >> hasChanged [
	^ true
]

{ #category : #accessing }
SoilNewClusterVersion >> indexOfBehaviorDescription: aBehavior [
	| index |
	(aBehavior = SoilBehaviorDescription) ifTrue: [ ^ 0 ]. 
	index := behaviorDescriptions 
		detectIndex: [ :each | each behaviorIdentifier = aBehavior name ]
		ifNone: [ 0 ].
	(index > 0) ifTrue: [ ^ index ].
	behaviorDescriptions add: (transaction behaviorDescriptionFor: aBehavior).
	^ behaviorDescriptions size
]

{ #category : #accessing }
SoilNewClusterVersion >> indexOfExternalReference: anObject [
	| index |
	(anObject == object) ifTrue: [ ^ 0 ].
	index := externalObjects identityIndexOf: anObject.
	(index > 0) ifTrue: [
		"anObject is an external object but has already been registered. Just
		returning the index of the registered reference"
		^ index ].
	transaction objectIndex
		at: anObject
		ifPresent: [ :record |
			"anObject is an external object. Allocate a new local index and
			return that"
			self addObject: record object reference: record objectId.
			^ references size ]
		ifAbsent: [ | record |
			(anObject class isSoilClusterRoot) ifTrue: [
				"anObject could be made cluster root per class side setting. In that
				case we add it as cluster root to the transaction so the following
				will find it"
				transaction addClusterObject: anObject.
				record := transaction objectIndex at: anObject.
				self addObject: record object reference: record objectId.
				^ references size ].
			].
	^ 0
]

{ #category : #initialization }
SoilNewClusterVersion >> initialize [
	super initialize.
	externalObjects := SoilObjectTable new
]

{ #category : #'as yet unclassified' }
SoilNewClusterVersion >> initializeObjectIdsIn: aSOTransaction [ 
	"assign indexes to all not yet initialized object records"
	((references copyWithFirst: objectId) reject: #isInitialized) do: [ :oid |
		aSOTransaction initializeObjectId: oid ]
]

{ #category : #'public/accessing' }
SoilNewClusterVersion >> lockIndex [
	^ transaction lockObjectId: objectId
]

{ #category : #accessing }
SoilNewClusterVersion >> position: anInteger [ 
	position := anInteger
]

{ #category : #accessing }
SoilNewClusterVersion >> previousVersionRecord: anObject [

	previousVersionRecord := anObject
]

{ #category : #printing }
SoilNewClusterVersion >> printOn: aStream [ 
	aStream << 'new record: '.
	objectId printOn: aStream.
	aStream << ' previous postion: ' << previousVersionPosition asString.
	aStream << ' '.
	object printOn: aStream.
	
]

{ #category : #serializing }
SoilNewClusterVersion >> serialize [
	^ ByteArray streamContents: [ :stream |
		self serializeOn: stream ]
				
]

{ #category : #serializing }
SoilNewClusterVersion >> serializeObject [
	bytes := ByteArray streamContents: [ :s |
		transaction newSerializer 
			stream: s;
			externalObjectRegistry: self;
			serialize: object ].
	^ bytes
]

{ #category : #serializing }
SoilNewClusterVersion >> serializeOn: stream [
	| serializer |
	bytes ifNil: [ self serializeObject ].
	self flag: #todo.
	serializer := SoilBasicSerializer new stream: stream.

	serializer 
		nextPutLengthEncodedInteger: version;
		nextPutLengthEncodedInteger: previousVersionPosition.
		
	serializer
		nextPutLengthEncodedInteger: behaviorDescriptions size.
	behaviorDescriptions do: [ :behavior |
		serializer 
			nextPutLengthEncodedInteger: behavior objectId index;
			nextPutLengthEncodedInteger: behavior version ].
		
	serializer nextPutLengthEncodedInteger: references size.
	references do: [ :ref |
		"do not write zero index, try to allocate a new index before"
		(ref index = 0) ifTrue: [ 
			transaction allocateObjectId: ref ].
		ref writeOn: stream ].
	serializer nextPutLengthEncodedInteger: bytes size.
	stream nextPutAll: bytes .
]

{ #category : #testing }
SoilNewClusterVersion >> shouldBeCommitted [
	^ true
]

{ #category : #'as yet unclassified' }
SoilNewClusterVersion >> validateReadVersion [
	"a new object record cannot conflict as the record is not on disk"
	(previousVersionPosition = 0) ifTrue: [ ^ self ].
	(previousVersionPosition = (transaction objectRepository positionOf: objectId)) ifFalse: [ 
		SoilObjectHasConcurrentChange signal: 'object id: ', objectId asString, ' has been changed by another transaction']
]
