Class {
	#name : #SoilLockableStream,
	#superclass : #Object,
	#instVars : [
		'imageLocked',
		'fileLocked',
		'fileStream',
		'lockRegistry',
		'locks'
	],
	#category : #'Soil-File'
}

{ #category : #'instance creation' }
SoilLockableStream class >> path: aStringOrFileReference [ 
	^ self new 
		initializePath: aStringOrFileReference;
		yourself
]

{ #category : #'initialize-release' }
SoilLockableStream >> close [
	self releaseAllLocks.
	fileStream ifNotNil: [  
		fileStream closed 
			ifFalse: [ fileStream close ] ].

]

{ #category : #finalization }
SoilLockableStream >> finalize [ 
	self close
]

{ #category : #writing }
SoilLockableStream >> flush [
	^ fileStream flush
]

{ #category : #initialization }
SoilLockableStream >> initialize [ 
	super initialize.
	locks := OrderedCollection new.
	self class finalizationRegistry add: self.
	imageLocked := true.
	fileLocked := true.
]

{ #category : #initialization }
SoilLockableStream >> initializePath: aStringOrFileReference [ 
	fileStream := aStringOrFileReference asFileReference binaryReadWriteStream.
	lockRegistry := SoilFileLockRegistry forPath: aStringOrFileReference asFileReference 
]

{ #category : #locking }
SoilLockableStream >> lockAppendingFor: lockContext [
	^ self registerLock: (self lockClass from: 0 to: 0 context: lockContext)

]

{ #category : #locking }
SoilLockableStream >> lockClass [
	^ SoilRangeLock 
]

{ #category : #locking }
SoilLockableStream >> lockFrom: from length: length for: lockContext [ 
	
	^ self registerLock: (self lockClass from: from length: length context: lockContext)

]

{ #category : #locking }
SoilLockableStream >> lockFrom: from to: to for: lockContext [ 

	^ self registerLock: (self lockClass from: from to: to context: lockContext)

]

{ #category : #'as yet unclassified' }
SoilLockableStream >> lockOnlyInImage [
	imageLocked := true.
	fileLocked := false.
]

{ #category : #accessing }
SoilLockableStream >> locks [
	^ locks
]

{ #category : #reading }
SoilLockableStream >> next [
	^ fileStream next 
]

{ #category : #reading }
SoilLockableStream >> next: anInteger [ 
	^ fileStream next: anInteger 
]

{ #category : #writing }
SoilLockableStream >> nextPut: anInteger [ 
	fileStream nextPut: anInteger
]

{ #category : #writing }
SoilLockableStream >> nextPutAll: aString [ 
	fileStream nextPutAll: aString 
]

{ #category : #positioning }
SoilLockableStream >> position [
	^ fileStream position
]

{ #category : #positioning }
SoilLockableStream >> position: anInteger [ 
	fileStream position: anInteger 
]

{ #category : #locking }
SoilLockableStream >> registerLock: lock [
	
	imageLocked ifTrue: [ 
		lock lockInMemory: lockRegistry ].
	
	fileLocked ifTrue: [ 
		lock lockOn: fileStream  ].
	
	^ locks add: lock
	
]

{ #category : #finalization }
SoilLockableStream >> releaseAllLocks [
	locks copy do: [ :lock | 
		locks remove: lock.
		lock release ].
	locks := OrderedCollection new
]

{ #category : #accessing }
SoilLockableStream >> size [ 
	^ fileStream size
]

{ #category : #locking }
SoilLockableStream >> unlockFrom: from to: to for: lockContext [ 
	
	| lock |
	lock := locks 
		detect: [ :each | 
			(each from = from) & (each to = to) & (each context = lockContext) ]
		ifNone: [ NotFound signal: 'cannot find lock' ].
	lock release.
	locks remove: lock
	
]
