configLoader = require '../index'
fs = require 'fs'

# NOTE: Since the transformations to the string are the same regardless of
# it coming from a file (sync or async loaded) or being passed as a parameter
# all the tests use the sync mode. Take this into account if you are going
# to make changes in those transformations.

# TODO: Add test for "encoding" method.

describe 'configLoader', ->
	it 'parses a JSON file and returns its contents as a POJO', (done) ->
		fs.readFile './spec/fixtures/simple.json', 'utf8', (err, data) ->
			result = configLoader.parse data

			expect(result).toEqual {
				a: 'a'
				b: 'b'
			}

			done()

	it 'loads a json file, parses it and returns its contents as a POJO', ->
		result = configLoader.load.sync './spec/fixtures/simple.json'

		expect(result).toEqual {
			a: 'a'
			b: 'b'
		}

	it 'loads a coffee file, parses it and returns its contents as a POJO', ->
		result = configLoader.load.sync './spec/fixtures/simple.coffee'
		expect(result).toEqual {
			a: 'a'
			b: 'b'
		}

	it 'returns a POJO with environment dependent properties moved into "ENV" key', ->
		result = configLoader.load.sync './spec/fixtures/simple-env.json', 'qa'

		expect(result).toEqual {
			ENV:
				__environment: 'qa'
				domain: 'domain.qa'
				port: '80'
		}

	it 'uses "dev" as environment if none provided', ->
		result = configLoader.load.sync './spec/fixtures/simple-env.json'
		expect(result.ENV.__environment).toEqual 'dev'

	it 'merges "common" and "environment dependent" keys', ->
		result = configLoader.load.sync './spec/fixtures/config.coffee'
		expect(result.ENV.port).toEqual '80'
		expect(result.ENV.apiKey).toEqual 12

	it 'merges "common" and "environment dependent" keys and makes the second prevail', ->
		result = configLoader.load.sync './spec/fixtures/config.coffee'
		expect(result.ENV.test).toEqual 'two'

	it 'uses provided key as root to search for environment dependent data', ->
		result = configLoader.srcKey 'envs'
			.load.sync './spec/fixtures/config-different-key.coffee'
		expect(result.ENV.port).toEqual '80'
		expect(result.ENV.apiKey).toEqual 12

	it 'uses provided key as root to store environment dependent data', ->
		result = configLoader.destKey 'environment'
			.load.sync './spec/fixtures/config-different-key.coffee'
		expect(result.environment.port).toEqual '80'
		expect(result.environment.apiKey).toEqual 12

describe 'configLoader in asynchronous mode', ->
	it 'returns a promise', (done) ->
		result = configLoader.load './spec/fixtures/simple.json'
		expect(result.then).toBeDefined()
		expect(result.catch).toBeDefined()

		done()


