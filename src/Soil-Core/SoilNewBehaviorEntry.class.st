Class {
	#name : #SoilNewBehaviorEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'identifier',
		'objectId'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewBehaviorEntry class >> journalTypeCode [ 
	^ 7
]

{ #category : #accessing }
SoilNewBehaviorEntry >> address [
	^ identifier 
]

{ #category : #commiting }
SoilNewBehaviorEntry >> commitIn: aSoilTransaction [ 
	aSoilTransaction behaviorRegistry 
		nameAt: identifier  
		put: objectId 
]

{ #category : #accessing }
SoilNewBehaviorEntry >> container [
	^ #behaviorRegistry
]

{ #category : #accessing }
SoilNewBehaviorEntry >> context [ 
	^ objectId 
]

{ #category : #'as yet unclassified' }
SoilNewBehaviorEntry >> effect [
	^ identifier 
]

{ #category : #accessing }
SoilNewBehaviorEntry >> identifier: aString [ 
	identifier := aString 
]

{ #category : #accessing }
SoilNewBehaviorEntry >> objectId [
	^ objectId
]

{ #category : #accessing }
SoilNewBehaviorEntry >> objectId: aSoilObjectId [ 
	objectId := aSoilObjectId 
]

{ #category : #printing }
SoilNewBehaviorEntry >> printOn: aStream [ 
	super printOn: aStream.
	aStream 
		<< ' objectId: '
		<< objectId asString
		<< ' name: ' 
		<< identifier asString
		
]

{ #category : #'instance creation' }
SoilNewBehaviorEntry >> readFrom: aStream [ 
	| size |
	super readFrom: aStream.
	objectId := SoilObjectId readFrom: aStream.
	size := (aStream next: 2) asInteger.
	identifier := (aStream next: size) asString
]

{ #category : #accessing }
SoilNewBehaviorEntry >> value [ 
	^ objectId
]

{ #category : #writing }
SoilNewBehaviorEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	objectId writeOn: aStream.
	aStream nextPutAll: (identifier size asByteArrayOfSize: 2).
	aStream nextPutAll: identifier asByteArray
]
