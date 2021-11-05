const variables = require('./variables');
const session = require('express-session');
const database = require("./db_connection");
let MySQLStore = require('express-mysql-session')(session);
let connectionPool = database.newPool();

let options = {
    host     : '190.111.211.91',
    port     : 33060,   
    user     : 'bdtdeploy',
    password : 'Leg0las2K19',
    database :  variables.databaseName,
    clearExpired : true,
    checkExpirationInterval: 15000,
    expiration: 15000,
    createDatabaseTable: true,
	schema: {
		tableName: 'sessions',
		columnNames: {
			session_id: 'session_id',
			expires: 'session_expires',
			data: 'session_data'
		}
	}
}

function createStore(){
    /*
    let connection =  connectionPool.getConnection(function(err, connection){
        if (err) throw err;
        return connection;
    });
    */
    return new MySQLStore(options);
}

module.exports = ({createStore});