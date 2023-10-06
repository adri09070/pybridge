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
