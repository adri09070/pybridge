Class {
	#name : 'PharoBridgeObjectLiteral',
	#superclass : 'PharoBridgeObject',
	#instVars : [
		'literalValue'
	],
	#category : 'PyBridge-core',
	#package : 'PyBridge',
	#tag : 'core'
}

{ #category : 'instance creation' }
PharoBridgeObjectLiteral class >> with: aLiteral [
	| instance dict |
	instance := self new literalValue: aLiteral; yourself.
	dict := { #value -> aLiteral } asDictionary .
	instance post: dict action: #register_literal.
	^ instance
]

{ #category : 'accessing' }
PharoBridgeObjectLiteral >> literalValue [

	^ literalValue
]

{ #category : 'accessing' }
PharoBridgeObjectLiteral >> literalValue: anObject [

	literalValue := anObject
]

{ #category : 'as yet unclassified' }
PharoBridgeObjectLiteral >> pharoBridgeInspectionSlots [

	^ self allInspectorNodes
]

{ #category : 'accessing' }
PharoBridgeObjectLiteral >> printOn: aStream [

	aStream << literalValue asString
]

{ #category : 'accessing' }
PharoBridgeObjectLiteral >> printString [

	^ literalValue asString
]

{ #category : 'accessing' }
PharoBridgeObjectLiteral >> value [
	^ literalValue 
]
