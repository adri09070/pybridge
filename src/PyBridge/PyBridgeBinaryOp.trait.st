Trait {
	#name : 'PyBridgeBinaryOp',
	#category : 'PyBridge-characteristics',
	#package : 'PyBridge',
	#tag : 'characteristics'
}

{ #category : 'arithmetic' }
PyBridgeBinaryOp >> * another [
	^ self __mult__: another
]

{ #category : 'arithmetic' }
PyBridgeBinaryOp >> + another [
	^ self __add__: another
]

{ #category : 'arithmetic' }
PyBridgeBinaryOp >> - another [
	^ self __sub__: another
]

{ #category : 'arithmetic' }
PyBridgeBinaryOp >> / another [
	^ self __truediv__: another
]
