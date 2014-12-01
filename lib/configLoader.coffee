fs = require 'fs'
path = require 'path'
Q = require 'q'
R = require 'ramda'
coffeeson = require 'coffeeson'
extend = require 'deep-extend'

###*
# @class configLoader
# @static
###

#######################################################################
#	PRIVATE UTILITY METHODS
#######################################################################

###*
# Default value for file encoding.
#
# @property fileEncoding
# @type String
# @private
###
fileEncoding = 'utf-8'

###*
# Default value for root key for environment dependent data on the config file.
#
# @property srcEnvironmentsKey
# @type String
# @private
###
srcEnvironmentsKey = 'environments'

###*
# Default value for root key for environment dependent data on the
# destination object.
#
# @property destEnvironmentsKey
# @type String
# @private
###
destEnvironmentsKey = 'ENV'

###*
# Loads a file asynchronously. Returns a promise that will be fullfilled
# when the loading is complete.
#
# @method loadFile
# @param {String} filePath Path to the file.
# @return Promise.
# @private
###
loadFile = (filePath) ->
	deferred = Q.defer()

	fs.readFile filePath, fileEncoding, (err, file) ->
		if err
			deferred.reject err
		else
			deferred.resolve file

	return deferred.promise

###*
# Parses a string into a JSON.
#
# @method toJSON
# @param {String} type Format (json, coffeeson...) of the string.
# @param {String} string String to be converted.
# @return {JSON} Resulting object.
# @private
###
toJSON = R.curry (type, string) ->
	if type is 'coffee'
		string = coffeeson.toJSON(string)

	return JSON.parse string

###*
# Moves environment dependent properties into a root node.
#
# @method setEnvironmentConfig
# @param {String} environment Current environment.
# @param {JSON} json Object containing environment dependent data.
# @return {JSON} Resulting object.
# @private
###
setEnvironmentConfig = R.curry (environment, json) ->
	if not json[srcEnvironmentsKey]
		return json

	if json[srcEnvironmentsKey].common
		envConfig = extend 	json[srcEnvironmentsKey].common,
							json[srcEnvironmentsKey][environment]
	else
		envConfig = json[srcEnvironmentsKey][environment]

	envConfig.__environment = environment

	json[destEnvironmentsKey] = envConfig
	delete json[srcEnvironmentsKey]

	return json

###*
# Merges a provided object with the one resulting of configuration parsing.
#
# @method updateConfigObject
# @param {Object} result Object sent to "configLoader".
# @param {JSON} json Configuration object.
# @return {Object} Resulting object.
# @private
###
updateConfigObject = R.curry (result, json) ->
	result = extend result, json
	return result

###*
# Curries and chains the above transformation methods so they can be called
# in sequence to operate on the source string.
#
# @method performFileTransformations
# @param {String} [type=json] Format (json, coffeeson...) of the string.
# @param {String} environment Current environment identifier.
# @param {Object} result Object where the configuration will be merged.
# @return {Function} Transformations chain.
# @private
###
performFileTransformations = (type = 'json', environment, result) ->
	return R.pipe toJSON(type),
				setEnvironmentConfig(environment),
				updateConfigObject(result)

#######################################################################
#	API
#######################################################################
###*
# Loads a config file, sets the appropriate environment dependent data and
# merges it with an optional provided object.
#
# @method load
# @param {String} filePath Path to the file.
# @param {String} [environment=dev] Current environment identifier.
# @param {Object} [result={}] Object where the configuration will be merged.
# @return {Promise} Promise.
###
load = (filePath, environment = 'dev', result = {}) ->
	extension = path.extname(filePath).substring(1)

	deferred = Q.defer()

	loadFile filePath
		.then performFileTransformations extension, environment, result
		.then deferred.resolve
		.catch (err) ->
			deferred.reject err


	return deferred.promise

###*
# Synchronous version of "load".
# See {{#crossLink "configLoader/load:method"}}{{/crossLink}}
#
# @method load.sync
# @param {String} filePath Path to the file.
# @param {String} [environment=dev] Current environment identifier.
# @param {Object} result Object where the configuration will be merged.
# @return {Object} Object with merged configuration.
###
load.sync = (filePath, environment = 'dev', result = {}) ->
	extension = path.extname(filePath).substring(1)

	src = fs.readFileSync filePath, fileEncoding
	return performFileTransformations(extension, environment, result)(src)

###*
# Parses a string into a config object with environment dependent keys.
#
# @method parse
# @param {String} src Source string.
# @param {String} [environment=dev] Current environment identifier.
# @param {Object} result Object where the configuration will be merged.
# @return {Object} Object with merged configuration.
###
parse = (src, environment = 'dev', result = {}) ->
	return performFileTransformations(null, environment, result)(src)

###*
# Sets the encoding to be used when opening files.
#
# @method encoding
# @param {String} [encoding=fileEncoding] Encoding.
# @return {configLoader} ConfigLoader.
###
encoding = (encoding = fileEncoding) ->
	fileEncoding = encoding
	return this

###*
# Sets value for root key for environment dependent data on the config file.
#
# @method srcKey
# @param {String} [key=srcKey] Root key.
# @return {configLoader} ConfigLoader.
###
srcKey = (key = srcEnvironmentsKey) ->
	srcEnvironmentsKey = key
	return this

###*
# Sets value for root key for environment dependent data on the
# destination object.
#
# @method destEnvironmentsKey
# @param {String} [key=destEnvironmentsKey] Root key.
# @return {configLoader} ConfigLoader.
###
destKey = (key = destEnvironmentsKey) ->
	destEnvironmentsKey = key
	return this

module.exports =
	parse: parse
	load: load
	encoding: encoding
	srcKey: srcKey
	destKey: destKey


