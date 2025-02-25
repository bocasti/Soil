Class {
	#name : #SoilObjectProxy,
	#superclass : #ProtoObject,
	#instVars : [
		'transaction',
		'objectId',
		'object'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'reflective operations' }
SoilObjectProxy >> doesNotUnderstand: aMessage [ 
	^ aMessage sendTo: self soilRealObject
]

{ #category : #inspector }
SoilObjectProxy >> inspectionObject [
	<inspectorPresentationOrder: 30 title: 'object'>
	^ StRawInspection on: self soilRealObject 

]

{ #category : #testing }
SoilObjectProxy >> isSoilProxy [ 
	^ true
]

{ #category : #accessing }
SoilObjectProxy >> objectId [

	^ objectId
]

{ #category : #accessing }
SoilObjectProxy >> objectId: anObject [

	objectId := anObject
]

{ #category : #'as yet unclassified' }
SoilObjectProxy >> objectIsNotLoaded [ 
	^ object isNil
]

{ #category : #printing }
SoilObjectProxy >> printOn: aStream [ 
	aStream << 'proxy ' << objectId asString.
	object ifNotNil: [ 
		aStream <<  ': '.
		object printOn: aStream ]
]

{ #category : #printing }
SoilObjectProxy >> printString [ 
	^ String streamContents: [ :s | self printOn: s ] limitedTo: 1000 
]

{ #category : #'as yet unclassified' }
SoilObjectProxy >> soilLoadedIn: aTransaction [ 
	transaction := aTransaction  
]

{ #category : #'reflective operations' }
SoilObjectProxy >> soilRealObject [
	^ object ifNil: [  
		object := transaction objectWithId: objectId ]
]

{ #category : #'as yet unclassified' }
SoilObjectProxy >> soilSerialize: aSerializer [ 
	^ self soilRealObject soilSerialize: aSerializer 
]

{ #category : #'as yet unclassified' }
SoilObjectProxy >> theNonSoilProxy [ 
	^ self soilRealObject
]

{ #category : #accessing }
SoilObjectProxy >> transaction: aTransaction [ 
	transaction := aTransaction 
]
