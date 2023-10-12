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
