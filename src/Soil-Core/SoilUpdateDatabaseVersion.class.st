Class {
	#name : #SoilUpdateDatabaseVersion,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'version',
		'previousVersion'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilUpdateDatabaseVersion class >> journalTypeCode [ 
	^ 5
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> address [
	^ #databaseVersion
]

{ #category : #committing }
SoilUpdateDatabaseVersion >> commitIn: aSoilTransaction [ 
	aSoilTransaction soil databaseVersion: version
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> container [
	^ #soil
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> context [
	^ #global
]

{ #category : #'as yet unclassified' }
SoilUpdateDatabaseVersion >> effect [ 
	^ version 
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> oldValue [ 
	^ previousVersion 
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> previousVersion: anInteger [ 
	previousVersion := anInteger
]

{ #category : #printing }
SoilUpdateDatabaseVersion >> printOn: aStream [ 
	super printOn: aStream.
	aStream 
		<< ' version: '
		<< version asString.
]

{ #category : #'instance creation' }
SoilUpdateDatabaseVersion >> readFrom: aStream [ 
	super readFrom: aStream.
	version := (aStream next: 8) asInteger.
	previousVersion := (aStream next: 8) asInteger
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> value [ 
	^ version
]

{ #category : #accessing }
SoilUpdateDatabaseVersion >> version: anInteger [ 
	version := anInteger
]

{ #category : #writing }
SoilUpdateDatabaseVersion >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream nextPutAll: (version asByteArrayOfSize: 8).
	aStream nextPutAll: (previousVersion asByteArrayOfSize: 8).
]
