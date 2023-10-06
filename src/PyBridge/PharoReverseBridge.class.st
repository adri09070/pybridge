Class {
	#name : 'PharoReverseBridge',
	#superclass : 'PyReverseBridge',
	#category : 'PyBridge-core',
	#package : 'PyBridge',
	#tag : 'core'
}

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
	server := server
		ifNil: [ Teapot
				configure:
					{(#defaultOutput -> #ston).
					(#debugMode -> true).
					(#port -> 5000)} ].
	server start.
	self registerRoutes
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
