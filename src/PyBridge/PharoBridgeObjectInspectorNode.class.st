Class {
	#name : 'PharoBridgeObjectInspectorNode',
	#superclass : 'Object',
	#instVars : [
		'key',
		'value'
	],
	#category : 'PyBridge-core',
	#package : 'PyBridge',
	#tag : 'core'
}

{ #category : 'accessing' }
PharoBridgeObjectInspectorNode >> key [

	^ key
]

{ #category : 'accessing' }
PharoBridgeObjectInspectorNode >> key: anObject [

	key := anObject
]

{ #category : 'accessing' }
PharoBridgeObjectInspectorNode >> rawValue [
	"Answer the object value of this object variable (slot, indexed attribute, computed value)."
	^ value
]

{ #category : 'accessing' }
PharoBridgeObjectInspectorNode >> value: anObject [

	value := anObject
]
