Class {
	#name : 'PharoBridge',
	#superclass : 'Object',
	#instVars : [
		'server',
		'instanceMap'
	],
	#category : 'PyBridge-core',
	#package : 'PyBridge',
	#tag : 'core'
}

{ #category : 'reflective operations' }
PharoBridge class >> createInstance: aClassSymbol [

	^ PharoBridgeObject new createInstance: aClassSymbol
]

{ #category : 'reflective operations' }
PharoBridge class >> createInstance: aClassSymbol args: anArray [

	^ PharoBridgeObject new createInstance: aClassSymbol args: anArray
]

{ #category : 'accessing' }
PharoBridge class >> flushInstances [

	<script>
	PharoBridgeObject instanceMap removeAll
]

{ #category : 'reflective operations' }
PharoBridge class >> isRunning [

	| reverseServer |
	reverseServer := PharoBridgeObject reverseServer.
	^ reverseServer isNotNil and: [ reverseServer isRunning ]
]

{ #category : 'reflective operations' }
PharoBridge class >> load: aClassSymbol [
	"Ask for a class in the remote environment"

	self isRunning ifFalse: [ self restart ].
	^ PharoBridgeClass new loadClass: aClassSymbol
]

{ #category : 'reflective operations' }
PharoBridge class >> loadClass: aClassSymbol [
	"Ask for a class in the remote environment"

	self isRunning ifFalse: [ self restart ].
	^ PharoBridgeClass new loadClass: aClassSymbol
]

{ #category : 'accessing' }
PharoBridge class >> start [

	<script>
	^ self startAtPort: 5000
]

{ #category : 'accessing' }
PharoBridge class >> startAtPort: anInteger [

	| server |
	server := PharoBridgeObject reverseServer.
	server ifNil: [
		server := PharoReverseBridge new.
		PharoBridgeObject reverseServer: server ].
	^ server startAtPort: anInteger
]

{ #category : 'accessing' }
PharoBridge class >> stop [
	"PharoBridgeObject removeServer"

	<script>
	| reverseServer |
	reverseServer := PharoBridgeObject reverseServer.
	reverseServer ifNotNil: [
		reverseServer stop.
		reverseServer flushInstances ].
	self flushInstances
]
