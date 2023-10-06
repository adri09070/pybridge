Trait {
	#name : 'PyBridgeCallable',
	#category : 'PyBridge-characteristics',
	#package : 'PyBridge',
	#tag : 'characteristics'
}

{ #category : 'as yet unclassified' }
PyBridgeCallable >> call [
	^ self __call__
]
