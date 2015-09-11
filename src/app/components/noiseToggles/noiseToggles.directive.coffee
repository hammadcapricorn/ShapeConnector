'use strict'

app.directive 'scNoiseToggles', [
	'$log'
	'gameSettingsService'
	'assetsService'
	( $log, gameSettings, assetsService) ->
		templateUrl: 'app/components/noiseToggles/noiseToggles.html'
		restrict: 'E'
		scope: true
		link: ($scope, el, attrs) ->
			$scope.noises =
				sounds: {
					label: 'Sound'
					allowed: gameSettings.getAllowSounds()
				}
				music: {
					label: 'Music'
					allowed: gameSettings.getAllowMusic()
				}

			$scope.toggleNoise = ( type ) ->
				$scope.noises[type].allowed = gameSettings.toggle( type )
				if type is 'music'
					if $scope.noises[type].allowed is yes
						assetsService.playSound('background')
					else
						assetsService.pauseSound('background')
				return

]