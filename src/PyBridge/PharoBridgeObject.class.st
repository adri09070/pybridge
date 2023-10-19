Class {
	#name : 'PharoBridgeObject',
	#superclass : 'Object',
	#instVars : [
		'objectId'
	],
	#classVars : [
		'baseTargetUrl',
		'instanceMap',
		'reverseServer'
	],
	#classInstVars : [
		'string2class'
	],
	#category : 'PyBridge-core',
	#package : 'PyBridge',
	#tag : 'core'
}

{ #category : 'accessing' }
PharoBridgeObject class >> baseTargetUrl [

	^ baseTargetUrl ifNil: [ baseTargetUrl := 'http://127.0.0.1:5000/' ]
]

{ #category : 'accessing' }
PharoBridgeObject class >> baseTargetUrl: anObject [

	baseTargetUrl := anObject
]

{ #category : 'reflective operations' }
PharoBridgeObject class >> decryptAnswer: aZNResponse [
	| dict |
	dict := STON fromString: aZNResponse contents.
	^ self decryptPharoElement: dict
]

{ #category : 'reflective operations' }
PharoBridgeObject class >> decryptException: aDict [

	PyBridgeException
		fromClass: (aDict at: #class)
		signal: (aDict at: #args) asString
		withArgs: (aDict at: #args)
]

{ #category : 'reflective operations' }
PharoBridgeObject class >> decryptLiteral: aDict [

	| value |
	value := aDict at: #value.
	^ PyBridgeObjectLiteral with: value
]

{ #category : 'reflective operations' }
PharoBridgeObject class >> decryptObject: aDict [
	| object ston_object remote_id |
			
	ston_object := aDict at: #value.
	remote_id := ston_object at: #object_id.
	object := self instanceMap
		at: remote_id
		ifAbsent: [ | new_object dict |			
			new_object := (self string2class at: (aDict at: #kind)) new.
			self instanceMap at: new_object bridgeUUID put: new_object.
			dict := {(#remote_id -> remote_id)} asDictionary.
			new_object post: dict action: #register_object.
			new_object ].
	^ object
]

{ #category : 'reflective operations' }
PharoBridgeObject class >> decryptPharoElement: dict [

	dict isArray ifTrue: [ 
		^ dict collect: [ :e | self decryptPharoElement: e ] ].
	dict isDictionary ifFalse: [ ^ dict ].
	dict at: #kind ifAbsent: [ ^ dict "should be recursive" ]. 
	(dict at: #kind) = 'literal' ifTrue: [ ^ self decryptLiteral: dict ].
	(dict at: #kind) = 'object' ifTrue: [ ^ self decryptObject: dict ].
	(dict at: #kind) = 'type' ifTrue: [ ^ self decryptObject: dict ].
	(dict at: #kind) = 'nil_object' ifTrue: [ ^ nil ].
	(dict at: #kind) = 'exception' ifTrue: [ 
		^ self decryptException: dict ]
]

{ #category : 'reflective operations' }
PharoBridgeObject class >> instanceMap [
	^ instanceMap := instanceMap ifNil: [ WeakValueDictionary new ]
]

{ #category : 'removing' }
PharoBridgeObject class >> removeServer [
	<script>
	reverseServer ifNil: [ ^ self ]. 
	reverseServer stop.
	reverseServer := nil
]

{ #category : 'reflective operations' }
PharoBridgeObject class >> reverseServer [
	^ reverseServer
]

{ #category : 'reflective operations' }
PharoBridgeObject class >> reverseServer: aServer [
	reverseServer := aServer
]

{ #category : 'accessing' }
PharoBridgeObject class >> string2class [

	^ string2class := string2class ifNil: [
		                  {
			                  (#object -> PharoBridgeObject).
			                  (#type -> PharoBridgeClass) } asDictionary ]
]

{ #category : 'reflective operations' }
PharoBridgeObject >> bridgeUUID [

	^ self bridgeUUIDOf: self
]

{ #category : 'reflective operations' }
PharoBridgeObject >> bridgeUUIDOf: anObject [
	^ anObject identityHash 
]

{ #category : 'reflective operations' }
PharoBridgeObject >> createInstance: aClassSymbol [
	"Ask for an instances creation to the remote environment"
	| dict |
	dict := {(#class_name -> aClassSymbol)} asDictionary.
	self instanceMap at: objectId put: self.
	
	self post: dict action: #create_instance
]

{ #category : 'reflective operations' }
PharoBridgeObject >> createInstance: aClassSymbol args: anArray [
	"Ask for an instances creation to the remote environment with args"

	| dict |
	dict := {(#class_name -> aClassSymbol).
	(#args -> anArray)} asDictionary.
	self instanceMap at: objectId put: self.
	self post: dict action: #create_instance
]

{ #category : 'reflective operations' }
PharoBridgeObject >> doesNotUnderstand: aMessage [

	^ self performCall: aMessage selector args: aMessage arguments
]

{ #category : 'reflective operations' }
PharoBridgeObject >> encryptValue: aValue [
	| id kind |
	aValue isLiteral
		ifTrue: [ ^ aValue ].
	aValue isDictionary
		ifTrue: [ ^ aValue ].
	id := self bridgeUUIDOf: aValue.
	self reverseServerIsRunning ifTrue: [ self reverseServer instanceMap at: id ifAbsentPut: [ aValue ] ].
	aValue isBlock
		ifTrue: [ kind := #block ]
		ifFalse: [ aValue isClass
				ifTrue: [ kind := #type ]
				ifFalse: [ kind := #object ] ].
	^ {(#object_id -> (self bridgeUUIDOf: aValue)).
	(#kind -> kind)} asDictionary
]

{ #category : 'finalization' }
PharoBridgeObject >> finalize [
	"Ask for a clean of the object in the remote environement"

	[ self post: Dictionary new action: #instance_delete ]
		on: ConnectionTimedOut
		do: [ :ex | self ]
]

{ #category : 'initialization' }
PharoBridgeObject >> initialize [
	objectId := self bridgeUUID.
	self finalizationRegistry add: self.
]

{ #category : 'reflective operations' }
PharoBridgeObject >> instanceMap [
	^ self class instanceMap
]

{ #category : 'reflective operations' }
PharoBridgeObject >> performCall: methodName args: arguments [
	| args dict |
	args := arguments collect: [ :each | self encryptValue: each ].
	dict := {(#args -> args).
	(#key -> methodName)} asDictionary.
	^ self class decryptAnswer: (self post: dict action: #instance_call)
]

{ #category : 'reflective operations' }
PharoBridgeObject >> post: dict action: action [

	dict at: #object_id put: objectId.
	dict at: #action put: action.
	^ ZnEasy
		  post: self class baseTargetUrl , objectId asString
		  data:
		  (ZnEntity
			   with: (STON toString: dict)
			   type: ZnMimeType applicationSton)
]

{ #category : 'printing' }
PharoBridgeObject >> printOn: aStream [

	^ self doesNotUnderstand:
		  (Message selector: #printOn: argument: aStream)
]

{ #category : 'printing' }
PharoBridgeObject >> printString [

	^ self doesNotUnderstand: (Message selector: #printString)
]

{ #category : 'reflective operations' }
PharoBridgeObject >> reverseServer [
	^ self class reverseServer 
]

{ #category : 'reflective operations' }
PharoBridgeObject >> reverseServerIsRunning [
	^ self reverseServer isNotNil and: [ self reverseServer isRunning ]
]
