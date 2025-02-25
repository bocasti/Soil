Class {
	#name : #SoilBTreeTest,
	#superclass : #TestCase,
	#instVars : [
		'btree'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #running }
SoilBTreeTest >> setUp [ 
	super setUp.
	btree := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 8;
		valueSize: 8
]

{ #category : #running }
SoilBTreeTest >> tearDown [ 
	btree ifNotNil: [ 
		btree close ].
	super tearDown
]

{ #category : #tests }
SoilBTreeTest >> testAddFirstOverflow [

	| page capacity |
	capacity := btree headerPage itemCapacity.
	1 to: capacity do: [ :n | btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: btree pages size equals: 2.
	self assert: (btree pageAt: 1) numberOfItems equals: 255.
	"if we add a page, the current one is split and half is moved there"
	btree at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: btree pages size equals: 3.
	page := btree pageAt: 3.
	self assert: page numberOfItems equals: 128.
	self assert: page items first key equals: 129.
	self assert: page items last key asByteArray equals: #[ 1 0 ].
	"check that the next pointer is correct after split"
	self assert: (btree pageAt:((btree headerPage) next)) identicalTo: (btree pageAt: 3)
]

{ #category : #tests }
SoilBTreeTest >> testAddRandom [
	| numEntries entries |
	"just some random addind and checking that we can find it. tree is configured to create lots of pages"
	btree := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 512;
		valueSize: 512.
	
	numEntries := 20.
	entries := Set new: numEntries.
	
	
	numEntries timesRepeat: [ | toAdd |
		toAdd := (numEntries*20) atRandom.
		entries add: toAdd.
		btree at: toAdd  put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (btree at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]].
]

{ #category : #tests }
SoilBTreeTest >> testAddSecondOverflow [

	| page capacity |
	capacity := btree headerPage itemCapacity.
	1 to: capacity do: [ :n | btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: btree pages size equals: 2.
	self assert: (btree pageAt: 1) numberOfItems equals: 255.
	"if we add a page, the current one is split and half is moved there"
	1 to: capacity do: [ :n | btree at: capacity + n put: #[ 1 2 3 4 5 6 7 8 ]].
	self assert: btree pages size equals: 4.
	page := btree pageAt: 4.
	self assert: page numberOfItems equals: 254.
	self assert: page items first key equals: 257.
	"check that the next pointer is correct after split"
	self assert: ((btree headerPage nextPageIn: btree) nextPageIn: btree) identicalTo: (btree pageAt: 4).
	btree writePages.
]

{ #category : #tests }
SoilBTreeTest >> testAddSecondOverflowReload [
	| page capacity |

	capacity := btree headerPage itemCapacity.
	1 to: capacity do: [ :n | btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: btree pages size equals: 2.
	self assert: (btree pageAt: 1) numberOfItems equals: 255.
	"if we add a page, the current one is split and half is moved there"
	1 to: capacity do: [ :n | btree at: capacity + n put: #[ 1 2 3 4 5 6 7 8 ]].
	self assert: btree pages size equals: 4.
	page := btree pageAt: 4.
	self assert: page numberOfItems equals: 254.
	self assert: page items first key equals: 257.
	"check that the next pointer is correct after split"
	self assert: ((btree headerPage nextPageIn: btree) nextPageIn: btree) identicalTo: (btree pageAt: 4).

	btree writePages.
	btree close.
	btree := SoilBTree new 
		path: 'sunit-btree';
		initializeFilesystem;
		open. 
	self assert: (btree at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : #tests }
SoilBTreeTest >> testAt [

	| capacity |
	capacity := btree headerPage itemCapacity.
	1 to: capacity do: [ :n | btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: btree pages size equals: 2.
	self assert: (btree pageAt: 1) numberOfItems equals: 255.
	"if we add a page, the current one is split and half is moved there"
	btree at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: btree pages size equals: 3.
	
	self assert: (btree at: 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (btree at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (btree at: capacity + 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ btree at: capacity + 2  ] raise: KeyNotFound
]

{ #category : #tests }
SoilBTreeTest >> testAtNoOverflow [

	| capacity |
	capacity := btree headerPage itemCapacity.
	1 to: capacity do: [ :n | btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: btree pages size equals: 2.
	self assert: (btree pageAt: 1) numberOfItems equals: 255.
	self assert: btree pages size equals: 2.
	
	self assert: (btree at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ btree at: capacity + 1  ] raise: KeyNotFound
	
]

{ #category : #tests }
SoilBTreeTest >> testAtSecondOverflow [

	| capacity |
	capacity := btree headerPage itemCapacity.
	1 to: capacity do: [ :n | btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: btree pages size equals: 2.
	self assert: (btree pageAt: 1) numberOfItems equals: 255.
	"if we add a page, the current one is split and half is moved there"
	1 to: capacity do: [ :n | btree at: capacity + n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: btree pages size equals: 4.
	
	self assert: (btree at: 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (btree at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (btree at: capacity + 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (btree at: capacity + capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ btree at: capacity * 2 + 1  ] raise: KeyNotFound
]

{ #category : #tests }
SoilBTreeTest >> testCreation [
	"we alwaus create one data page and the root index"
	self assert: btree pages size equals: 2.
	"both pages start as dirty"
	self assert: (btree pages at: 1) isDirty.
	self assert: (btree pages at: 2) isDirty
]

{ #category : #tests }
SoilBTreeTest >> testFirst [
	
	| capacity |
	capacity := btree headerPage itemCapacity * 2.

	2 to: capacity do: [ :n |
		btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	btree at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: btree pages size equals: 4.
	self assert: btree first equals: #[ 8 7 6 5 4 3 2 1 ].
	self assert: (btree first: 2) second equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : #tests }
SoilBTreeTest >> testIsEmpty [
	self assert: btree isEmpty.
	btree at: 1 put: #[1 2].
	self deny: btree isEmpty
]

{ #category : #tests }
SoilBTreeTest >> testIteratorFirst [
	
	| capacity first |
	capacity := btree headerPage itemCapacity * 2.
	btree at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: btree pages size equals: 4.
	first := btree newIterator first.
	self assert: first equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilBTreeTest >> testLast [
	
	| capacity |
	capacity := btree headerPage itemCapacity * 2.

	1 to: capacity - 1 do: [ :n |
		btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	btree at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: btree pages size equals: 4.
	self assert: btree last equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilBTreeTest >> testPageAddFirst [
	
	| page indexPage |
	btree at: #foo put: #[ 1 2 3 4 5 6 7 8 ].
	btree writePages.
	self assert: btree pages size equals: 2.
	page := btree headerPage.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: (#foo asSkipListKeyOfSize: 8) asInteger.
	"the index page was updated"
	indexPage := btree rootPage.
	"Index has been updated"
	self assert: indexPage items size equals: 1
	
	
]

{ #category : #tests }
SoilBTreeTest >> testPageAddFirstAndLoad [
	
	| page indexPage |
	btree at: #foo put: #[ 1 2 3 4 5 6 7 8 ].
	btree writePages.
	self assert: btree pages size equals: 2.
	page := btree headerPage.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: (#foo asSkipListKeyOfSize: 8) asInteger.
	"the index page was updated"
	indexPage := btree rootPage.
	"Index has been updated"
	self assert: indexPage items size equals: 1.

	"load back"
	
	btree close.
	btree := SoilBTree new 
		path: 'sunit-btree';
		initializeFilesystem;
		open.
	
	self assert: page items first key equals: (#foo asSkipListKeyOfSize: 8) asInteger.	
	"load succeeds"
	self assert: (btree at: #foo) equals: #[ 1 2 3 4 5 6 7 8 ].

]

{ #category : #tests }
SoilBTreeTest >> testRemoveKey [

	| capacity |
	capacity := btree headerPage itemCapacity.
	1 to: capacity do: [ :n | btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	btree removeKey: 20.
	
	self assert: (btree at: 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (btree at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ btree at: 20  ] raise: KeyNotFound.
	btree at: 20 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (btree at: 20) equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : #tests }
SoilBTreeTest >> testSize [
	
	| capacity |
	capacity := btree headerPage itemCapacity.
	btree at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		btree at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	btree at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: btree pages size equals: 3.
	self assert: btree size equals: capacity + 1.
]

{ #category : #tests }
SoilBTreeTest >> testSplitIndexPage [
	| entries |
	"this test leads to a split of a non-root index page"
	btree := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 512;
		valueSize: 512.
	
	entries :=  #(104 247 56 281 61 286 66 337 308 1 400 272 347 335 45 62 207 7 123 140).
	
	
	entries do: [:toAdd |
		btree at: toAdd  put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (btree at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]].
]

{ #category : #tests }
SoilBTreeTest >> testSplitIndexPageReleoad [
	| entries |
	"this test leads to a split of a non-root index page"
	btree := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 512 ;
		valueSize: 512.
	
	entries :=  #(104 247 56 281 61 286 66 337 308 1 400 272 347 335 45 62 207 7 123 140).
	
	
	entries do: [:toAdd |
		btree at: toAdd  put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (btree at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]].
	
	"write and reload"
	btree writePages.
	btree close.
	btree := SoilBTree new 
		path: 'sunit-btree';
		initializeFilesystem;
		open. 
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (btree at: each ) equals: (#[ 1 2 3 4 5 6 7 8 ] asByteArrayOfSize: 512)].
]

{ #category : #tests }
SoilBTreeTest >> testSplitRootIndexPage [ 
	"we add until the root Index is full and has to be split"
	| capacity n indexPages |
	n := 1.
	capacity := btree headerPage itemCapacity.
	[btree rootPage hasRoom] whileTrue: [
		btree at: n put: #[ 1 2 3 4 5 6 7 8 ].
		n:= n+1. ].
	self assert: btree pages size equals: 410.
	
	"if we lots of more pages, the root index has to be split"
	1 to: capacity do: [ :i | btree at:  i + n put: #[ 1 2 3 4 5 6 7 8 ]].
	
	self assert: btree pages size equals: 413.
	indexPages := btree pages values select: [ :each | each isKindOf: SoilBTreeIndexPage ].
	"we now have indeed three index pages"
	self assert: indexPages size equals: 3.
	self assert: btree rootPage equals: indexPages third.
	"the root page now points to the new index page"
	self assert: (btree rootPage items anySatisfy: [ :item | item value asInteger = indexPages first index ]).
	"and we can find the key added last"
	self assert: (btree at: capacity + n ) equals:  #[ 1 2 3 4 5 6 7 8 ]
]

{ #category : #tests }
SoilBTreeTest >> testSplitRootIndexPageReload [
	"we add until the root Index is full and has to be split"
	| capacity n |
	n := 1.
	capacity := btree headerPage itemCapacity.
	[btree rootPage hasRoom] whileTrue: [
		btree at: n put: #[ 1 2 3 4 5 6 7 8 ].
		n:= n+1. ].
	self assert: btree pages size equals: 410.
	
	"if we lots of more pages, the root index has to be split"
	1 to: capacity do: [ :i | btree at:  i + n put: #[ 1 2 3 4 5 6 7 8 ]].

	btree writePages.
	btree close.
	btree := SoilBTree new 
		path: 'sunit-btree';
		initializeFilesystem;
		open. 
	
	"and we can find the key added last"
	self assert: (btree at: capacity + n ) equals:  #[ 1 2 3 4 5 6 7 8 ].
]
