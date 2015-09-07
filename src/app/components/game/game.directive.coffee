'use strict'

#===============================================================================
#
#	Game Directive
# 		Renders the game to the canvas and handles the events
#
#-------------------------------------------------------------------------------

app.directive 'appGame', [
	'$rootScope'
	'$log'
	'LEVELS'
	'BOARD'
	'SHAPE'
	'GameManagerService'
	'WatcherService'
	($rootScope, $log, LEVELS, BOARD, SHAPE, GameManager, Watcher) ->
		templateUrl: 'app/components/game/partials/game.html'
		restrict: 'E'
		scope:
			sourceGame: '=?'
			difficulty: '@?'
			onNewGame: '&?'
			onResetGame: '&?'
		link: ($scope, el, attrs) ->
			# globals
			Game = null
			$window = $(window)
			$gameHeader = el.find('.game-header')
			watcher = new Watcher( $scope )


			# utils: simple functions used to render the board
			#-------------------------------------------------------------------
			utils =
				calcGameWidth: ->
					gameWidth = BOARD.DIMENSIONS.w + 150
					if $window.width() < gameWidth
						gameWidth = $window.width() - 30

					return gameWidth

				calcGameTopMargin: ->
					windowMidHeight = $window.height() / 2
					boardHalfHeight = BOARD.DIMENSIONS.h / 2
					headerHeight = $gameHeader.outerHeight(true)
					goalHeight = $scope.canvasCollection.goal.$el.outerHeight(true)

					topMargin = windowMidHeight - boardHalfHeight - goalHeight - headerHeight
					topMargin = 60 if topMargin < 0

					return topMargin


			# setup: creates variables to be used when we render + start the game
			#-------------------------------------------------------------------
			setup = ->
				# Default the game difficulty to easy
				$scope.difficulty ?= LEVELS.DEFAULT.name

				# Collection of canvases to be drawn on
				$scope.canvasCollection = {}

				# The dimenisions (sizes) of the canvases we need
				$scope.canvasDimensions =
					goal: {
						width: BOARD.DIMENSIONS.w
						height: SHAPE.OUTERSIZE
					}
					timer: {
						width: SHAPE.OUTERSIZE
						height: SHAPE.OUTERSIZE
					}
					board: {
						width: BOARD.DIMENSIONS.w
						height: BOARD.DIMENSIONS.h
					}

				# Callback events for the game canvas
				$scope.gameCanvasEvents =
					start: events.onMove
					move: events.onMove
					end: events.onEnd
					cancel: events.onCancel


			# start: create and render a new game
			#-------------------------------------------------------------------
			start = ->
				# ALL of the game logic: Creates a game that uses the specified
				# canvases, difficulty, and optional source game board
				Game = new GameManager( $scope.canvasCollection, $scope.difficulty, $scope.sourceGame )

				# Save the current game board to the parent (controller) scope
				saveGameBoard()

				# Position the board correctly on the window
				positionBoard()

				# Create a scoped copy of the Game class
				$scope.game = Game.start()

				$rootScope.windowEvents.onFocus( events.onFocus )
				$rootScope.windowEvents.onBlur( events.onBlur )


			# saveGameBoard: Save the current game board to the controller
			#-------------------------------------------------------------------
			saveGameBoard = ->
				if not $scope.sourceGame?
					$scope.sourceGame = angular.copy(Game.cacheGameBoard)


			# positionBoard: Update the position of the board on the screen
			#-------------------------------------------------------------------
			positionBoard = ->
				$game = el.find('.game')
				$gameBoardContainer = $game.find('.game-board-wrapper')
				$gameBoard = $game.find('.game-board')
				$gamePopup = $game.find('.game-popup')

				$game.css(
					width: utils.calcGameWidth()
					marginTop: utils.calcGameTopMargin()
				)
				$gameBoardContainer.css(width: BOARD.DIMENSIONS.w)
				$gameBoard.css(height: BOARD.DIMENSIONS.h)
				$gamePopup.css(
					width: BOARD.DIMENSIONS.w
					height: BOARD.DIMENSIONS.h
				)


			# events
			# 	Bind gameboard the touch/mouse events to the corresponding
			# 	method in the Game manager
			#	Note: Keep $scope.$apply since events are bound outåside of angular
			#-------------------------------------------------------------------
			events =
				onMove: ( e, params ) -> $scope.$apply( => Game.onMoveEvent(e, params) )
				onEnd: -> $scope.$apply( => Game.onEndEvent() )
				onCancel: -> $scope.$apply( => Game.onCancelEvent() )
				onFocus: -> $scope.$apply( => Game.resumeGame() )
				onBlur: -> $scope.$apply( => Game.pauseGame() )


			# actions: Additonal user triggered actions on game win/lose
			#-------------------------------------------------------------------
			$scope.actions =
				newGame: -> $scope.onNewGame?(params: true)
				resetGame: -> $scope.onResetGame?(params: Game.cacheGameBoard)
				quitGame: -> $scope.onQuitGame?(params: true)


			# We're ready to set the scope variables
			setup()

			# Watch the canvasCollection for updates - start the game when
			# we have the game canvas data
			stopCanvasWatch = watcher.start('canvasCollection', (collection) ->
				if collection?.game?
					stopCanvasWatch()
					start()
			)

			# Destroy the Game class on directive $destroy
			$scope.$on('$destroy', () ->
				Game.destroy()
			)
]



app.animation '.game-popup', [
	'$log'
	($log) ->
		return {
			addClass: (element, className, done) ->
				if className is 'ng-hide'
					$el = $(element)
					$el.show()
					$el.css(top: '0%')
					$el.animate({top: '100%'}, 500, () ->
						$el.hide()
						$el.css(top: '100%')
					)

				return

			removeClass: (element, className, done) ->
				if className is 'ng-hide'
					$el = $(element)
					$el.hide().css(top: '100%')
					$el.show().animate({top: '0%'}, 500, () ->
						$el.show()
						$el.css(top: '0%')
					)

				return
		}
]