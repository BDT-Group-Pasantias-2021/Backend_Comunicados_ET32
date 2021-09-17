const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const session = require('express-session');
const database = require("./db_connection");
const genuuid=require('uuid');
const mysqlsessionstore = require("./session_store");

var pool = database.newPool();
var sessionStore = mysqlsessionstore.createStore();

const app = express();
const port = 3001;
const router = express.Router();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(cors());
app.use(session({name: "SessionCookie", secret: "test", cookie: {maxAge : 600000}, store: sessionStore, resave:true }));


app.route("/Frontend_Comunicados_ET32/register").post(function (req, res) {
    //
    const data = req.body;
    let sql = `SELECT insert_user(${data.documento}, "${data.nombre}", "${data.apellido}", '2000-11-11', '0000000000', '1', '${data.email}', '${data.password}', '${data.confirmar_contraseña}', ${data.tipo_documento})`;
	try {
		pool.getConnection(function(err, connection){
            if (err) throw err;
            connection.query(sql, function (err, result) {
                if (err) throw err;
                let registerAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
                console.log(registerAccepted);
                console.log(JSON.parse(JSON.stringify(result[0])));
                res.json(registerAccepted);
                connection.release();
                return;
                });
        });
	} catch (error) {
		console.log(error);
	}
});

  app.route("/Frontend_Comunicados_ET32/login").post(async function (req, res) {
    const data = req.body;
    req.session.cookie.email = data.email;
    let sql = `SELECT bdt_cuaderno.login_user_node_session("${data.email}", "${data.password}")`;
	try {
        pool.getConnection(function(err, connection){
            if (err) throw err;
                connection.query(sql, function (err, result) {
                    req.session.email = data.email;
                    req.session.save();
                    if (err) throw err;
                    let loginAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
                    if(loginAccepted == 1) {
                      let sqlSession = `SELECT bdt_cuaderno.restrict_session("${req.sessionID}", "${data.email}")`;

                      connection.query(sqlSession, function (err2, resulta2) {
                        if (err2) throw err2;
                        console.log(resulta2[0]);
                      });
                      res.json(req.sessionID);
                    }else{
                      res.send("Usuario o contraseña incorrectos.");
                    }
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