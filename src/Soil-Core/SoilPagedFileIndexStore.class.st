Class {
	#name : #SoilPagedFileIndexStore,
	#superclass : #SoilPagedIndexStore,
	#instVars : [
		'stream',
		'streamSemaphore'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #converting }
SoilPagedFileIndexStore >> asCopyOnWriteStore [
	^ SoilCopyOnWriteIndexStore new 
		wrappedStore: self
]

{ #category : #'open/close' }
SoilPagedFileIndexStore >> close [ 
	stream ifNotNil: [  
		stream close.
		stream := nil ]
]

{ #category : #'instance creation' }
SoilPagedFileIndexStore >> filePageSize [
	"most OSses use a file page size of 4k today"
	^ 4096
]

{ #category : #flushing }
SoilPagedFileIndexStore >> flush [
	self flushPages 
]

{ #category : #flushing }
SoilPagedFileIndexStore >> flushPages [
	pagesMutex critical: [  
		pages valuesDo: [ :page |
			page isDirty ifTrue: [ 
				self writePage: page ] ] ]
]

{ #category : #testing }
SoilPagedFileIndexStore >> hasStream [
	^ stream notNil
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initialize [ 
	super initialize.
	streamSemaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initializeFilesystem [
	self openStream
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initializeHeaderPage [
	| page |
	page := index newHeaderPage.
	pagesMutex critical: [  
		pages at: page index put: page	]
]

{ #category : #'open/close' }
SoilPagedFileIndexStore >> open [
	self 
		openStream;
		readHeaderPage 
]

{ #category : #'open/close' }
SoilPagedFileIndexStore >> openStream [
	stream := SoilLockableStream path: index path.
]

{ #category : #accessing }
SoilPagedFileIndexStore >> pageFaultAt: anInteger [
	| page |
	streamSemaphore critical: [  
		stream position: (self positionOfPageIndex: anInteger).
		page := index readPageFrom: stream ].
	pagesMutex critical: [  
		pages at: anInteger put: page ].
	^ page
]

{ #category : #accessing }
SoilPagedFileIndexStore >> pagesStart [
	^ 4096
]

{ #category : #'instance creation' }
SoilPagedFileIndexStore >> positionOfPageIndex: anInteger [
	^ ((anInteger - 1) * self filePageSize)
]

{ #category : #writing }
SoilPagedFileIndexStore >> readHeaderPage [
	| headerPage |
	streamSemaphore critical: [  
		stream position: 0.
		stream next. "pageCode"
		headerPage :=  index newHeaderPage readFrom: stream ].
	pagesMutex critical: [  
		pages at: 1 put: headerPage ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> replace: oldPage with: newPage [ 
	pagesMutex critical: [  
		pages
			at: oldPage index 
			put:newPage ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> stream [
	^ stream 
]

{ #category : #writing }
SoilPagedFileIndexStore >> writeHeaderPage [
	streamSemaphore critical: [  
		self stream position: 0.
		self headerPage writeOn: self stream ]
]

{ #category : #writing }
SoilPagedFileIndexStore >> writePage: aPage [ 
	| pagePosition |
	streamSemaphore critical: [  
		pagePosition := self positionOfPageIndex: aPage index.  
		stream position: pagePosition.
		aPage writeOn: stream.
		stream flush ]
]
