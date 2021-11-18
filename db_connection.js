const mysql = require('mysql');

function newPool() {
	let pool = mysql.createPool({
		host: '190.111.211.91',
		port: '33060',
		user: 'bdtdeploy',
		password: 'Leg0las2K19',
		database: 'bdt_cuaderno',
	});
	return pool;
}

module.exports = { newPool };
