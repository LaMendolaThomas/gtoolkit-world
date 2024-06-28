Class {
	#name : #GtHomeLepiterKnowledgeBaseTabGroupElement,
	#superclass : #LeDatabaseElement,
	#instVars : [
		'tabGroupElement',
		'tocTab',
		'tocPage'
	],
	#category : #'GToolkit-World-Helpers'
}

{ #category : #'private - updating' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> createDailyNotesElement [
	^ GtHomeLepiterDailyNotesElement new
		databaseViewModel: self database asContentUIModel
]

{ #category : #'private - updating' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> createDailyNotesTabElement [
	^ BrTab new
		aptitude: GtHomeLepiterCardTabAptitude new;
		label: 'Pages';
		stencil: [ self createDailyNotesElement ]
]

{ #category : #'private - updating' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> createTableOfContentsElement [
	^ GtHomeLepiterTableOfContentsElement new
		databaseViewModel: self database asContentUIModel
]

{ #category : #'private - updating' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> createTableOfContentsTabElement [
	^ BrTab new
		aptitude: GtHomeLepiterCardTabAptitude new;
		label: 'Table of contents';
		stencil: [ self createTableOfContentsElement ]
]

{ #category : #'private - updating' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> ensureTableOfContentsTab [
	tocTab ifNil: [ tocTab := self createTableOfContentsTabElement ].
	(tabGroupElement hasTab: tocTab) ifTrue: [ ^ self ].

	tabGroupElement addTab: tocTab at: 1.
]

{ #category : #testing }
GtHomeLepiterKnowledgeBaseTabGroupElement >> hasTableOfContents [
	<return: #Boolean>
	^ self database tableOfContents isNotNil
]

{ #category : #initialization }
GtHomeLepiterKnowledgeBaseTabGroupElement >> initialize [
	super initialize.

	self initializeTabGroupElement.
	self addChild: tabGroupElement as: #group.

	self matchParent.
	self padding: (BlInsets all: 10)
]

{ #category : #initialization }
GtHomeLepiterKnowledgeBaseTabGroupElement >> initializeTabGroupElement [
	tabGroupElement := BrTabGroup new
			aptitude: BrGlamorousTabGroupAptitude new;
			actionbarStencil: [ BrToolbar new
					aptitude: BrGlamorousToolbarAptitude new;
					addItem: self searchButton;
					yourself ]
]

{ #category : #'api - ui model' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> onContentUIModelChanged [
	super onContentUIModelChanged.

	tabGroupElement tabs copy do: [ :eachTab | 
		tabGroupElement removeTab: eachTab ].
	tocTab := nil.
	tabGroupElement addTab: self createDailyNotesTabElement.
	self onTableOfContentsPageUUIDChanged.
	self updateElement
]

{ #category : #'event handling' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> onTableOfContentsPageUUIDChanged [
	| aNewTocPage |
	aNewTocPage := self tableOfContents.
	tocPage == aNewTocPage ifTrue: [ ^ self ].
	
	tocPage := aNewTocPage.
	self removeTableOfContentsTab.
]

{ #category : #'event handling' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> onTableOfContentsPageUUIDChanged: anAnnouncement [
	BlTaskAction
		enqueueElement: self
		action: [ 
			self onTableOfContentsPageUUIDChanged.
			self updateElement ]
]

{ #category : #'private - updating' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> removeTableOfContentsTab [
	tocTab ifNil: [ ^ self ].
	tabGroupElement removeTab: tocTab.
	tocTab := nil
]

{ #category : #'private - updating' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> searchButton [
	^ GtSpotterDropdownButtonStencil new
		beSmallSize;
		valuable: (GtHomeLepiterKnowledgeBaseSpotterStart new databaseProvider: self);
		tooltip: 'Search Pages';
		objectActOn: [ :anActOnEvent :anItem :theButton | 
			theButton fireEvent: BrDropdownHideWish new.
			self spawnPage: anItem from: theButton.
			anActOnEvent beActed. ];
		asElement
]

{ #category : #'event handling' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> spawnPage: aPage from: aButton [
	"If we are in a pager, spawn the page in the current phlow, else create a new pager."

	^ aButton
		allParentsDetect: [ :aParent | aParent isKindOf: GtPager ]
		ifFound: [ :aParent | aButton phlow spawnTool: aPage asPhlowTool ]
		ifNone: [ 
			GtWorldUtility
				showSpaceWithTitle: aPage title
				inPagerWith: [ aPage asLepiterPagePhlowTool asElementDo: [ :e | e ] ]
						asStencil
				from: aButton ]
]

{ #category : #'private - subscriptions' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> subscribeToContent [
	"Subclasses can subscribe to what they are interested in.
	All subscriptions to the model should be weak.
	Announcements may happen in a non-UI process."

	super subscribeToContent.
	self database weak
		when: LeDatabaseTableOfContentsUUIDChanged send: #onTableOfContentsPageUUIDChanged: to: self
]

{ #category : #'private - subscriptions' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> unsubscribeFromContent [
	super unsubscribeFromContent.
	self database unsubscribe: self
]

{ #category : #'private - updating' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> updateElement [
	self updateTabGroupElement
]

{ #category : #'private - updating' }
GtHomeLepiterKnowledgeBaseTabGroupElement >> updateTabGroupElement [
	self hasTableOfContents
		ifTrue: [ self ensureTableOfContentsTab ]
		ifFalse: [ self removeTableOfContentsTab ]
]