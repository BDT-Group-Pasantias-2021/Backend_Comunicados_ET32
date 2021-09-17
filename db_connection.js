const mysql = require('mysql');

function newPool() {
    let pool = mysql.createPool({
    host     : 'localhost',
    user     : 'root',
    password : '',
    database : 'bdt_cuaderno'
  });
  return pool;
}

module.exports= {newPool};