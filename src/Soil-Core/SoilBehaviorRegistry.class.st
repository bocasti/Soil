Class {
	#name : #SoilBehaviorRegistry,
	#superclass : #Object,
	#instVars : [
		'soil',
		'index',
		'versions'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SoilBehaviorRegistry >> addSpecialObjects [
	self
		nameAt: #SoilBehaviorDescription
		put: SoilBehaviorDescription metaId
]

{ #category : #'as yet unclassified' }
SoilBehaviorRegistry >> behaviorDescriptionWithIndex: behaviorIndex andVersion: version transaction: transaction [
	| versionsOfBehavior |

	self loadHistoryForBehaviorWithIndex: behaviorIndex transaction: transaction.

	versionsOfBehavior := versions at: behaviorIndex ifAbsent: [Error signal: 'shouldnt happen'].

	^versionsOfBehavior
		detect: [ :behav | behav version = version ]
		ifNone: [(SoilObjectNotFound new segment: 0; index: behaviorIndex) signal]
]

{ #category : #'as yet unclassified' }
SoilBehaviorRegistry >> behaviorVersionsUpTo: aSOBehaviorDescription transaction: transaction [
	| objectId chain offset |
	objectId := self 
		nameAt: aSOBehaviorDescription behaviorIdentifier 
		ifAbsent: [ Error signal: 'shouldnt happen' ].
	self loadHistoryForBehaviorWithIndex: objectId index transaction: transaction.
	chain := versions at: objectId index.
	chain first isCurrent ifFalse: [ 
		chain addFirst: ((SoilBehaviorDescription for: aSOBehaviorDescription objectClass) version: (aSOBehaviorDescription version + 1))].
	offset := chain detectIndex: [ :each | each matchesDescription: aSOBehaviorDescription ].
	^ chain copyFrom: 1 to: offset
]

{ #category : #'initialize-release' }
SoilBehaviorRegistry >> close [
	index close
]

{ #category : #accessing }
SoilBehaviorRegistry >> flush [
	self index flush
]

{ #category : #accessing }
SoilBehaviorRegistry >> index [
	^ index 
]

{ #category : #initialization }
SoilBehaviorRegistry >> initialize [

	super initialize.
	versions := Dictionary new
		            at: 2
		            put: (OrderedCollection with: SoilBehaviorDescription meta); yourself
]

{ #category : #initialization }
SoilBehaviorRegistry >> initializeFilesystem [
	index := SoilSkipList new 
		path: self path;
		initializeFilesystem;
		initializeHeaderPage;
		maxLevel: 10;
		keySize: 64;
		valueSize: 8.
	self addSpecialObjects.
	index writePages
]

{ #category : #'as yet unclassified' }
SoilBehaviorRegistry >> loadHistoryForBehaviorWithIndex: objectIndex transaction: transaction [
	|  records chain |

	"check if we loaded the history already"
	(versions includesKey: objectIndex ) ifTrue: [ ^ self ].

	records := transaction objectRepository metaSegment allVersionsAt: objectIndex.
	chain := records collect: [ :record |
		record
			transaction: transaction;
			materializeObject;
			object  ].

	versions
		at: objectIndex
		put: chain
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier ifAbsent: aBlock [
	^ self index 
		at: classIdentifier 
		ifAbsent: aBlock
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier put: objectId [
	| dict |
	(objectId index = 0) ifTrue: [ Error signal: 'cannot add non-initialized object id' ].
	dict := self index newIterator
		at: classIdentifier put: objectId;
		yourself
]

{ #category : #'instance creation' }
SoilBehaviorRegistry >> open [ 
	index ifNotNil: [ index close ].
	index :=  SoilSkipList new 
		path: self path;
		open
]

{ #category : #accessing }
SoilBehaviorRegistry >> path [
	^ soil objectRepository metaSegment identifierIndexPath
]

{ #category : #accessing }
SoilBehaviorRegistry >> soil: aSoil [ 
	soil := aSoil
]
