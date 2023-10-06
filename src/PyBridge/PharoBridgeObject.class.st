Class {
	#name : 'PharoBridgeObject',
	#superclass : 'Object',
	#instVars : [
		'objectId'
	],
	#classVars : [
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
