Class {
	#name : 'PharoReverseBridge',
	#superclass : 'Object',
	#instVars : [
		'server',
		'instanceMap'
	],
	#category : 'PyBridge-core',
	#package : 'PyBridge',
	#tag : 'core'
}

{ #category : 'accessing' }
PharoReverseBridge >> decodeValue: anObject [

	| o |
	anObject isArray ifTrue: [
		^ anObject collect: [ :e | self decodeValue: e ] ].
	anObject isDictionary ifFalse: [ ^ anObject ].
	o := anObject.
	anObject at: #kind ifPresent: [
		(anObject at: #kind) = #nil_object ifTrue: [ ^ nil ].
		o := anObject at: #value ].
	^ self instanceMap at: (o at: #object_id) ifAbsentPut: [
		  | newObj dict |
		  newObj := PharoBridgeObject new.
		  PharoBridgeObject instanceMap at: newObj bridgeUUID put: newObj.
		  dict := { (#remote_id -> (o at: #object_id)) } asDictionary.
		  newObj post: dict action: #register_object.
		  newObj ]
]

{ #category : 'accessing' }
PharoReverseBridge >> deleteInstance: objectId [

	| instance |
	[
	instance := self instanceMap removeKey: objectId.
	self instanceMap keysAndValuesRemove: [ :k :v | v == instance ] ]
		on: Exception
		do: [ ^ nil ].
	^ nil
]

{ #category : 'accessing' }
PharoReverseBridge >> dispatchActions: req [
	| action entity |
	entity := STON fromString: req entity string.
	action := entity at: #action.
	action = 'instance_call'
		ifTrue: [ ^ (entity includesKey: #args)
				ifFalse: [ self
						instanceCall: (entity at: #key) asSymbol
						on: (entity at: #object_id) ]
				ifTrue: [ (entity includesKey: #order)
						ifTrue: [ self
								instanceCall: (entity at: #key) asSymbol
								on: (entity at: #object_id)
								withArgs: (entity at: #args)
								orderedAs: (entity at: #order) ]
						ifFalse: [ self
								instanceCall: (entity at: #key) asSymbol
								on: (entity at: #object_id)
								withArg: (entity at: #args) ] ] ].
	action = 'get_class'
		ifTrue: [ ^ self
				loadClass: (entity at: #class_name)
				from: (req at: #obid) asInteger ].
	action = 'register_object'
		ifTrue: [ ^ self
				registerObject: (entity at: #remote_id)
				on: (entity at: #object_id) ].
	action = 'instance_delete'
		ifTrue: [ ^ self deleteInstance: (entity at: #object_id) ].
	action = 'register_literal'
		ifTrue: [ ^ self
				registerLiteral: (entity at: #value)
				on: (entity at: #object_id) ]
]

{ #category : 'accessing' }
PharoReverseBridge >> encryptBlock: anObject [

	^ {
		  (#kind -> #block).
		  (#value
		   -> { (#object_id -> (self objectId: anObject)) } asDictionary) }
		  asDictionary
]

{ #category : 'accessing' }
PharoReverseBridge >> encryptClass: aClass [

	^ {
		  (#kind -> #type).
		  (#value
		   -> { (#object_id -> (self objectId: aClass)) } asDictionary) }
		  asDictionary
]

{ #category : 'accessing' }
PharoReverseBridge >> encryptLiteral: aLiteral [

	^ {
		  (#kind -> #literal).
		  (#value -> aLiteral) } asDictionary
]

{ #category : 'accessing' }
PharoReverseBridge >> encryptNil [

	^ { (#kind -> #nil_object) } asDictionary
]

{ #category : 'reflective operations' }
PharoReverseBridge >> encryptObject: anObject [

	^ {
		  (#kind -> #object).
		  (#value
		   -> { (#object_id -> (self objectId: anObject)) } asDictionary) }
		  asDictionary
]

{ #category : 'reflective operations' }
PharoReverseBridge >> encryptValue: anObject [

	anObject ifNil: [ ^ self encryptNil ].
	(anObject isLiteral and: [ anObject isSymbol not ]) ifTrue: [
		^ anObject ].
	anObject isBlock ifTrue: [ ^ self encryptBlock: anObject ].
	anObject isClass ifTrue: [ ^ self encryptClass: anObject ].
	(anObject isKindOf: PharoBridgeClass) ifTrue: [
		^ self encryptClass: anObject ].
	(anObject isKindOf: PharoBridgeObjectLiteral) ifTrue: [
		^ anObject value ].
	^ self encryptObject: anObject
]

{ #category : 'accessing' }
PharoReverseBridge >> flushInstances [

	self instanceMap removeAll
]

{ #category : 'accessing' }
PharoReverseBridge >> instanceCall: key on: objectId [

	| instance res |
	instance := self instanceMap at: objectId.
	res := instance perform: key.
	self instanceMap at: (self objectId: res) ifAbsentPut: [ res ].
	^ self encryptValue: res
]

{ #category : 'accessing' }
PharoReverseBridge >> instanceCall: key on: objectId withArg: anObject [

	| instance res args |
	instance := self instanceMap at: objectId.
	args := anObject isArray
		        ifTrue: [ self decodeValue: anObject ]
		        ifFalse: [ { (self decodeValue: anObject) } asArray ].
	res := instance perform: key withArguments: args.
	self instanceMap at: (self objectId: res) ifAbsentPut: [ res ].
	^ self encryptValue: res
]

{ #category : 'accessing' }
PharoReverseBridge >> instanceCall: key on: objectId withArgs: aDict [
	| instance res newKey |
	instance := self instanceMap
		at: objectId.
	newKey := ('' join: (aDict keys)) asSymbol. 
	res := instance perform: newKey withArguments: aDict values.
	self instanceMap at: (self objectId: res) ifAbsentPut: [ res ].
	^ self encryptValue: res
]

{ #category : 'accessing' }
PharoReverseBridge >> instanceCall: key on: objectId withArgs: aDict orderedAs: aDictOrder [

	| instance res newKey keyList newArgs |
	instance := self instanceMap at: objectId.
	keyList := OrderedCollection new.
	1 to: aDictOrder size do: [ :i |
	keyList add: (aDictOrder at: i asString) ].
	newKey := ('' join: keyList) asSymbol.
	newArgs := keyList collect: [ :e | self decodeValue: (aDict at: e) ].
	res := instance perform: newKey withArguments: newArgs asArray.
	self instanceMap at: (self objectId: res) ifAbsentPut: [ res ].
	^ self encryptValue: res
]

{ #category : 'accessing' }
PharoReverseBridge >> instanceMap [

	^ instanceMap ifNil: [ instanceMap := Dictionary new ]
]

{ #category : 'testing' }
PharoReverseBridge >> isRunning [

	^ server isNotNil and: [ server server isRunning ]
]

{ #category : 'accessing' }
PharoReverseBridge >> loadClass: className from: objectId [

	| class |
	class := Smalltalk at: className asSymbol.
	self instanceMap at: (self objectId: class) ifAbsentPut: [ class ].
	self instanceMap at: objectId ifAbsentPut: [ class ].
	^ self encryptValue: class
]

{ #category : 'accessing' }
PharoReverseBridge >> objectId: anObject [

	^ anObject identityHash
]

{ #category : 'accessing' }
PharoReverseBridge >> registerLiteral: literal on: remoteId [

	self instanceMap at: remoteId put: literal.
	^ remoteId
]

{ #category : 'accessing' }
PharoReverseBridge >> registerObject: objectId on: remoteId [

	| instance |
	instance := self instanceMap at: objectId.
	self instanceMap at: remoteId put: instance.
	^ remoteId
]

{ #category : 'accessing' }
PharoReverseBridge >> registerRoutes [
	server
		POST:
			'/<obid>'
				-> [ :req | 
					Transcript traceCr: req.
					[self dispatchActions: req]
						"on: Halt
						do: [ :e | e signal ];"
						on: Exception
						do: [ :e | 
							{(#kind -> #exception).
							(#class -> e class name).
							(#args -> e messageText)} asDictionary ] ].
	^ server
]

{ #category : 'accessing' }
PharoReverseBridge >> start [

	self startAtPort: 5000
]

{ #category : 'accessing' }
PharoReverseBridge >> startAtPort: anInteger [

	server := server ifNil: [
		          Teapot configure: {
				          (#defaultOutput -> #ston).
				          (#debugMode -> true).
				          (#port -> anInteger) } ].
	server start.
	self registerRoutes
]

{ #category : 'accessing' }
PharoReverseBridge >> stop [

	self isRunning ifFalse: [ ^ self ].
	server stop
]
