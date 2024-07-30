Class {
	#name : 'BaselineOfPyBridge',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPyBridge',
	#package : 'BaselineOfPyBridge'
}

{ #category : 'baselines' }
BaselineOfPyBridge >> baseline: spec [

	<baseline>
	spec for: #common do: [
		self setUpDependencies: spec.
		spec package: 'PyBridge' with: [ spec requires: #( 'Teapot' ) ].
		spec group: 'default' with: #( 'PyBridge' ) ]
]

{ #category : 'baselines' }
BaselineOfPyBridge >> setUpDependencies: spec [

	spec
		baseline: 'Teapot'
			with: [ spec
				repository: 'github://zeroflag/Teapot:master/source';
				loads: #('Deployment') ];
		import: 'Teapot'.
]
