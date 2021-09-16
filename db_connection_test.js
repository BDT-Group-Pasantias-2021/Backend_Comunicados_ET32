const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const mysql = require('mysql');

var pool = mysql.createPool({
    host     : 'localhost',
    user     : 'root',
    password : '',
    database : 'bdt_cuaderno'
  });

const app = express();
const port = 3001;
const router = express.Router();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(cors());

app.route("/Frontend_Comunicados_ET32/register").post(function (req, res) {
    //
    let sql = "SELECT insert_user(95825635, 'Samuel', 'Hernández', '2003-03-27', '1121678328', '1', 'sdho2023@gmail.com', 'ssssm', 'ssssm', 2)";
	try {
		pool.getConnection(function(err, connection){
            if (err) throw err;
            connection.query(sql, function (err, result) {
                if (err) throw err;
                let rows = JSON.parse(JSON.stringify(result[0]));
                console.log(rows);
                connection.release();
                return;
                });
        });
	} catch (error) {
		console.log(error);
	}
});

  app.route("/Frontend_Comunicados_ET32/validateSession").post(async function (req, res) {
    const data = req.body;
    let sql = `SELECT bdt_cuaderno.login_user("${data.email}", "${data.password}")`;
	try {
        pool.getConnection(function(err, connection){
            if (err) throw err;

                connection.query(sql, function (err, result) {
                    if (err) throw err;
                    var rows = JSON.parse(JSON.stringify(result[0]));
                    console.log(rows);
                    res.json(rows);
                    return;
                });

                connection.release();
        });
	} catch (error) {
		console.log(error);
	}
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}!`)
});