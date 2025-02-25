Class {
	#name : #SoilSkipListPageTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SoilSkipListPageTest >> testCreation [ 
	| page |
	page := SoilSkipListTruncPage new 
		index: 1;
		level: 8;
		pageSize: 4096;
		keySize: 16;
		valueSize: 8.
	self assert: page hasRoom
		
]

{ #category : #tests }
SoilSkipListPageTest >> testWriteAndRead [
	| page bytes readPage |
	page := SoilSkipListTruncPage new 
		index: 1;
		level: 8.
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilSkipListPage readPageFrom: bytes readStream keySize: 8 valueSize: 8.
	self assert: readPage index equals: 1.
	self assert: readPage level equals: 8.
	self deny: readPage isDirty 
]

{ #category : #tests }
SoilSkipListPageTest >> testWriteAndReadRightArray [
	| page bytes readPage |
	page := SoilSkipListTruncPage new 
		index: 1;
		level: 8;
		setRight: #( 1 2 3 4 5 6 7 8 ).
	self assert: page isDirty.
	bytes := ByteArray streamContents: [ :stream |
		page writeOn: stream ].
	self deny: page isDirty.
	readPage := SoilSkipListPage readPageFrom: bytes readStream keySize: 8 valueSize: 8. 
	self assert: readPage index equals: 1.
	self assert: readPage level equals: 8.
	self assert: readPage right equals: #( 1 2 3 4 5 6 7 8).
	self deny: readPage isDirty 
]
