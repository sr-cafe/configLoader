env = require('./index');

try{
	console.log('sync', env.load.sync('config.coffee'));
}catch(e){
	console.log('Sync error', e)
}

env.load('config.coffee')
	.then(function(result){
		console.log('From load', result, arguments.length);
	})
	.catch(function(err){
		console.log('Error', err)
	});