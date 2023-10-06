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
