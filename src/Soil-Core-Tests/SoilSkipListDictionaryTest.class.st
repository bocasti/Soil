Class {
	#name : #SoilSkipListDictionaryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #helper }
SoilSkipListDictionaryTest class >> classUnderTest [ 	
	^ SoilSkipListDictionary 
]

{ #category : #accessing }
SoilSkipListDictionaryTest >> path [ 
	^ 'soil-tests'
]

{ #category : #initialization }
SoilSkipListDictionaryTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilSkipListDictionaryTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testAddAndRemoveExistingList [
	| dict tx tx2 tx3 |
	"create skip list dictionary with a key ..."
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	"... and persist it"
	tx := soil newTransaction.
	tx root: dict.
	dict at: #foo put: #one.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"... and remove the key from the persisted list"
	tx2 root
		removeKey: #foo.
	tx2 commit.
	tx3 := soil newTransaction.
	self assert: (tx3 root at: #foo ifAbsent: [ nil ]) equals: nil.

]

{ #category : #tests }
SoilSkipListDictionaryTest >> testAddAndRemoveOnNewList [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
  	self 
		shouldnt: [ dict at: #foo put: #bar ]
		raise: Error.
	self assert: (dict at: #foo) equals: #bar.
	dict removeKey: #foo.
	self assert: dict size equals: 0
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testAddToExistingEmptyList [
	| dict tx tx2 tx3 tx4 |
	"create emtpy skip list dictionary ..."
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	"... and persist it"
	tx := soil newTransaction.
	tx root: dict.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"... add a key but do not commit"
	tx2 root
		at: #foo put: #bar.
	"open third transaction and try to read the added key. As tx2
	is not committed the key should not be visible here"
	tx3 := soil newTransaction.
	self deny: (tx3 root at: #foo ifAbsent: [#nope]) equals: #bar.
	"now commit the second transaction"
	tx2 commit.
	"try to read the key again. The key should not be visibile because
	the readVersion is older than the value for that key"
	self deny: (tx3 root at: #foo ifAbsent: [#nope]) equals: #bar.
	tx3 abort.	
	tx4 := soil newTransaction.
	self assert: (tx4 root at: #foo) equals: #bar
	
		
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testAddToExistingNonEmptyList [
	| dict tx tx2 tx3 tx4 |
	"create skip list dictionary with a key ..."
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	"... and persist it"
	tx := soil newTransaction.
	tx root: dict.
	dict at: #foo put: #one.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"... add a key but do not commit"
	tx2 root
		at: #foo put: #bar.
	"open third transaction and try to read the added key. As tx2
	is not committed the key should be the old one"
	tx3 := soil newTransaction.
	self assert: (tx3 root at: #foo) equals: #one.
	"now commit the second transaction"
	tx2 commit.
	"try to read the key again. The key should not be visibile because
	the readVersion is older than the value for that key"
	self assert: (tx3 root at: #foo) equals: #one.
	tx3 abort.	
	tx4 := soil newTransaction.
	self assert: (tx4 root at: #foo) equals: #bar.	
		
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testAddToNewList [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
  	self 
		shouldnt: [ dict at: #foo put: #bar ]
		raise: Error.
	self assert: (dict at: #foo) equals: #bar
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testFirst [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict first equals: #bar.
	self assert: (dict first: 1) first equals: #bar.
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testIsEmpty [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
		
	self assert: dict isEmpty.
	dict at: #foo put: #bar.
	self deny: dict isEmpty
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testLast [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict last equals: #bar2
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testSecond [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict second equals: #bar2
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testSize [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict size equals: 2
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testValues [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: (dict values includes: 'bar').
	self assert: (dict values includes: 'bar2')
]
