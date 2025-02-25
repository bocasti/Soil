Class {
	#name : #SoilMigrationTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'migrationClass'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassByteLayout [
	^ (SoilBaseTestObject << #SOMigrationObject
		layout: ByteLayout;
		package: self class package name) install
]

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassFixedLayout [
	^ (SoilBaseTestObject << #SOMigrationObject
		layout: FixedLayout;
		slots: { #one . #two }; 
		package: self class package name) install
]

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassFixedLayout2 [
	^ (SoilBaseTestObject << #SOMigrationObject2
		layout: FixedLayout;
		slots: { #one . #two }; 
		package: self class package name) install
]

{ #category : #helpers }
SoilMigrationTest >> createMigrationClassVariableLayout [
	^ (SoilBaseTestObject << #SOMigrationObject
		layout: VariableLayout;
		slots: { #one . #two }; 
		package: self class package name) install
]

{ #category : #accessing }
SoilMigrationTest >> path [ 
	^ 'soil-tests'
]

{ #category : #running }
SoilMigrationTest >> runCase [ 
	SystemAnnouncer uniqueInstance 
		suspendAllWhile: [ super runCase ]
]

{ #category : #running }
SoilMigrationTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem.
	migrationClass := self createMigrationClassFixedLayout
]

{ #category : #running }
SoilMigrationTest >> tearDown [ 
	migrationClass removeFromSystem.
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #'tests - change classlayout' }
SoilMigrationTest >> testMaterializingObjectByteLayputFromFixedLayout [
	| tx tx2 materializedRoot object |
	object := self createMigrationClassFixedLayout new.
	self deny: object class isVariable.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	"now we change the class to be a variable class with the same ivars"
	migrationClass := self createMigrationClassByteLayout.
	tx2 := soil newTransaction.

	self should: [materializedRoot := tx2 root] raise: SoilLayoutMigrationError

]

{ #category : #'tests - change classlayout' }
SoilMigrationTest >> testMaterializingObjectFixedLayputFromByteLayout [
	| tx tx2 materializedRoot object |

	"We can load Variable Byte object as a Fixed object, we raise an error"

	object := self createMigrationClassByteLayout new: 10.
	self assert: object class isVariable.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	"now we change the class to be a fixed class with the same ivars"
	migrationClass := self createMigrationClassFixedLayout.
	tx2 := soil newTransaction.

	self should: [materializedRoot := tx2 root] raise: SoilLayoutMigrationError
]

{ #category : #'tests - change classlayout' }
SoilMigrationTest >> testMaterializingObjectFixedLayputFromVariableLayout [
	| tx tx2 materializedRoot object |
	object := self createMigrationClassVariableLayout new.
	self assert: object class isVariable.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	"now we change the class to be a fixed class with the same ivars"
	migrationClass := self createMigrationClassFixedLayout.
	tx2 := soil newTransaction.

	materializedRoot := tx2 root.
	self deny: materializedRoot class isVariable.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #two) equals: 2
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectRenamedClass [
		| tx tx2 materializedRoot object |

	object := self createMigrationClassFixedLayout new.
	self deny: object class isVariable.
	tx := soil newTransaction.
	tx root: object.
	tx commit.
	"now we remove the class and create a new one with a different name"
	migrationClass removeFromSystem.
	migrationClass := self createMigrationClassFixedLayout2.

	"We have to tell soil that the class was renamed"
	soil renameClassNamed: #SOMigrationObject to: #SOMigrationObject2.

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class name equals: 'SOMigrationObject2'
]

{ #category : #'tests - change classlayout' }
SoilMigrationTest >> testMaterializingObjectVariableLayputFromFixedLayout [
	| tx tx2 materializedRoot object |
	object := self createMigrationClassFixedLayout new.
	self deny: object class isVariable.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object.
	tx commit.

	"now we change the class to be a variable class with the same ivars"
	migrationClass := self createMigrationClassVariableLayout.
	tx2 := soil newTransaction.

	materializedRoot := tx2 root.
	self assert: materializedRoot class isVariable.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #two) equals: 2
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectVariableLayputWithChangedShape [
	| tx tx2 materializedRoot object |
	object := self createMigrationClassVariableLayout new.
	self assert: object class isVariable.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #two);
		addSlot: #three asSlot.

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #three) equals: nil.	
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithChangedShape [
	| tx tx2 materializedRoot object |
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #two);
		addSlot: #three asSlot.

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #three) equals: nil.	
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithIVarRemovedAndAddedBack [

	| tx tx2 root materializedRoot object |

	"this test checks that removing an ivar and adding it back later means this is a new ivar,
	this makes sure iterating over behavior description history works, see
	 PointerLayout>>#updateIvars:with:for:"
	root := Dictionary new.
	object := migrationClass new.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	root at: #version1 put: object.
	tx root: root.
	tx commit.

	"now we change the class and store an object with the changed shape"

	migrationClass
		removeSlot: (migrationClass slotNamed: #two).

	object := migrationClass new.
	object
		instVarNamed: #one put: 'one'.
	root
		at: #version2 put: object.

	tx := soil newTransaction.
	tx root: root.
	tx commit.

	migrationClass := (SoilBaseTestObject << #SOMigrationObject
		layout: FixedLayout;
		slots: { #one .#two . #three };
		package: self class package name) install.

	"load back, the object at #varsion1 loads the stored two ivars"
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: ((materializedRoot at: #version1) instVarNamed: #one ) equals: 1.
	self assert: ((materializedRoot at: #version2) instVarNamed: #one ) equals: 'one'.
	"the ivar for both is nil"
	self assert: ((materializedRoot at: #version1) instVarNamed: #two ) equals: nil.
	self assert: ((materializedRoot at: #version2) instVarNamed: #two ) equals: nil
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithIvarRemoved [
	"We can load an object that was saved with two ivars even if the current class has just one"
	| tx tx2 materializedRoot object |
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #two).

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class instVarNames size equals: 1.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithIvarRemoved2 [
	"We can load an object that was saved with two ivars even if the current class has just one"
	| tx tx2 materializedRoot object |
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #one).

	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class instVarNames size equals: 1.
	self assert: (materializedRoot instVarNamed: #two) equals: 2.
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithIvarRemovedThenCommit [
	"We can load an object that was saved with two ivars even if the current class has just one"
	| tx tx2 materializedRoot object |
	object := migrationClass new.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object.
	tx commit.
	migrationClass
		removeSlot: (migrationClass slotNamed: #two).
	
	"load it"	
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class instVarNames size equals: 1.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.

	"lets try to commit with the class changed"
	tx := soil newTransaction.
	tx root: materializedRoot.
	tx commit.

	"load again"
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot class instVarNames size equals: 1.
	self assert: (materializedRoot instVarNamed: #one) equals: 1
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithMultipleChangesinHistory [
	| tx tx2 root materializedRoot object |

	"this test checks that we can read object where we change multiple times the class"
	root := Dictionary new.
	object := migrationClass new.
	object
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	root at: #version1 put: object.
	tx root: root.
	tx commit.

	"now we change the class and store an object with the changed shape"

	migrationClass
		removeSlot: (migrationClass slotNamed: #two).

	object := migrationClass new.
	object
		instVarNamed: #one put: 'one'.
	root
		at: #version2 put: object.

	tx := soil newTransaction.
	tx root: root.
	tx commit.

	"load back, the object at #varsion1 loads the stored two ivars"
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: ((materializedRoot at: #version1) instVarNamed: #one ) equals: 1.
	self assert: ((materializedRoot at: #version2) instVarNamed: #one ) equals: 'one'
]

{ #category : #tests }
SoilMigrationTest >> testMaterializingObjectWithReOrderedIvars [
	| tx tx2 materializedRoot object |
	
	"this test checks that we can read objects where the order of the ivars changed. This happens for 
	example when moving ivars up or down in the hierarchy"
	
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	
	migrationClass := (SoilBaseTestObject << #SOMigrationObject
		layout: FixedLayout;
		slots: { #two .#one }; 
		package: self class package name) install.
	
	
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #two) equals: 2
]

{ #category : #tests }
SoilMigrationTest >> testSerializingObjectWithChangedShape [
	| tx tx2 materializedRoot object tx3 description topDescription obj |
	object := migrationClass new.
	object 
		instVarNamed: #one put: 1;
		instVarNamed: #two put: 2.
	tx := soil newTransaction.
	tx root: object. 
	tx commit.
	tx2 := soil newTransaction.
	migrationClass 
		removeSlot: (migrationClass slotNamed: #two);
		addSlot: #three asSlot.
	tx2 markDirty: tx2 root.
	tx2 commit.
	
	tx3 := soil newTransaction.
	materializedRoot := tx3 root.
	self assert: (materializedRoot instVarNamed: #one) equals: 1.
	self assert: (materializedRoot instVarNamed: #three) equals: nil.
	description := tx3 behaviorDescriptionFor: materializedRoot class.
	self assert: description version equals: 2.
	topDescription := soil behaviorRegistry nameAt: materializedRoot class soilBehaviorIdentifier ifAbsent: [ self fail ].
	self assert: (soil objectRepository allVersionsOf: topDescription) size equals: 2
]
