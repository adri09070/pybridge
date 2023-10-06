Class {
	#name : 'PharoBridgeClass',
	#superclass : 'PharoBridgeObject',
	#category : 'PyBridge-core',
	#package : 'PyBridge',
	#tag : 'core'
}

{ #category : 'reflective operations' }
PharoBridgeClass >> loadClass: aClassSymbol [
	"Ask for a class in the remote environment"

	| dict |
	dict := { (#class_name -> aClassSymbol) } asDictionary.
	self instanceMap at: self bridgeUUID put: self.
	self post: dict action: #get_class
]

{ #category : 'instance creation' }
PharoBridgeClass >> new [

	^ self new: {  } asDictionary
]

{ #category : 'instance creation' }
PharoBridgeClass >> new: arguments [

	arguments ifEmpty: [ ^ self newFromDict: arguments ].
	((arguments at: 1) isKindOf: Association) ifTrue: [
		^ self newFromDict: arguments ].
	^ self newFromList: arguments
]

{ #category : 'instance creation' }
PharoBridgeClass >> newFromDict: arguments [

	| args dict |
	args := Dictionary new.
	arguments do: [ :item |
		args at: item key put: (self encryptValue: item value) ].
	dict := {
		        (#args -> args).
		        (#clazz -> (self encryptValue: self)).
		        (#nonexisting -> true) } asDictionary.
	^ self class decryptAnswer:
		  (self post: dict action: #create_instance)
]

{ #category : 'instance creation' }
PharoBridgeClass >> newFromList: arguments [

	| args dict |
	args := arguments collect: [ :item | self encryptValue: item ].
	dict := {
		        (#args -> args asArray).
		        (#clazz -> (self encryptValue: self)).
		        (#nonexisting -> true) } asDictionary.
	^ self class decryptAnswer:
		  (self post: dict action: #create_instance)
]
