Class {
	#name : #SoilRangeLock,
	#superclass : #Object,
	#instVars : [
		'from',
		'to',
		'context',
		'stream',
		'registry'
	],
	#category : #'Soil-File'
}

{ #category : #'instance creation' }
SoilRangeLock class >> from: from length: length context: lockContext [ 
	^ self new 
		from: from;
		to: from + length - 1;
		context: lockContext 
]

{ #category : #'instance creation' }
SoilRangeLock class >> from: from to: to context: lockContext [ 
	^ self new 
		from: from;
		to: to;
		context: lockContext 
]

{ #category : #'as yet unclassified' }
SoilRangeLock >> conflictsFrom: aFrom to: aTo context: contextObject [ 
	"conflicts if ranges overlap but only for different contexts"
	^ (self intersectsFrom: aFrom to: aTo) &  (context ~~ contextObject)
]

{ #category : #'as yet unclassified' }
SoilRangeLock >> conflictsWith: aSORangeLock [ 
	^ aSORangeLock conflictsFrom: from to: to context: context
]

{ #category : #accessing }
SoilRangeLock >> context [

	^ context
]

{ #category : #accessing }
SoilRangeLock >> context: anObject [

	context := anObject
]

{ #category : #accessing }
SoilRangeLock >> from [

	^ from
]

{ #category : #accessing }
SoilRangeLock >> from: anObject [

	from := anObject
]

{ #category : #'as yet unclassified' }
SoilRangeLock >> intersectsFrom: otherFrom to: otherTo [ 
	"other range is before"
	(otherTo < from) ifTrue: [ ^ false ].
	"other range is after"
	(to < otherFrom) ifTrue: [ ^ false ].
	^ true
]

{ #category : #testing }
SoilRangeLock >> isFrom: aFrom to: aTo for: contextObject [ 
	^ (from = aFrom)& (to = aTo) & (context = contextObject)
]

{ #category : #'as yet unclassified' }
SoilRangeLock >> lockInMemory: aLockRegistry [ 
	aLockRegistry addLock: self 
	 
]

{ #category : #'as yet unclassified' }
SoilRangeLock >> lockOn: aStream [ 
	stream := aStream wrappedStream.
	stream lockAt: from length: to - from 
]

{ #category : #printing }
SoilRangeLock >> printOn: aStream [ 
	aStream << 'range lock  ' 
		<< from asString << ' - ' << to asString.
	registry ifNotNil: [  
		aStream << ' mem ' << registry path asString ].
	stream ifNotNil: [  
		aStream << ' file ' << stream name asString ].
	aStream << ' '.
	context printOn: aStream
]

{ #category : #accessing }
SoilRangeLock >> registry [

	^ registry
]

{ #category : #accessing }
SoilRangeLock >> registry: anObject [

	registry := anObject
]

{ #category : #initialization }
SoilRangeLock >> release [ 
	stream ifNotNil: [ 
		stream unlockAt: from length: to - from.
		stream := nil ].
	registry ifNotNil: [ 
		registry removeLock: self.
		registry := nil ]
]

{ #category : #accessing }
SoilRangeLock >> stream [

	^ stream
]

{ #category : #accessing }
SoilRangeLock >> stream: anObject [

	stream := anObject
]

{ #category : #accessing }
SoilRangeLock >> to [

	^ to
]

{ #category : #accessing }
SoilRangeLock >> to: anObject [

	to := anObject
]
