const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const session = require('express-session');
const database = require("./db_connection");
const genuuid=require('uuid');
const mysqlsessionstore = require("./session_store");
const mailer = require("./email/template/send_email");
const sendEmail = require("./email/template/send_email");
let pool = database.newPool();
let sessionStore = mysqlsessionstore.createStore();

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



app.route("/Frontend_Comunicados_ET32/recoverPassword").post(function (req, res) {
   const data = req.body;
  let sqlRecovery = `select pass_recovery('${data.documento}', '${data.email}')`;
  let sqlTokenId = `SELECT recovery_token FROM personas where email = "${data.email}";`;
  try {
    pool.getConnection(function(err, connection){

        if (err) throw err;
            connection.query(sqlRecovery, function (err, result) {
              if (err) throw err;
              let isNewToken = Object.values(result[0])[0];
              if(isNewToken === "0"){
                res.send("TIMESTAMP -> ESPERAR 30 MINUTOS  ");
                //TIMESTAMP -> ESPERAR 30 MINUTOS  
                console.log("TIMESTAMP -> ESPERAR 30 MINUTOS ");
                return; 
              }
              console.log();
              connection.query(sqlTokenId, function (err, result) {
                if (err) throw err;
                if(result[0] === undefined){return};
                console.log(result[0]);
                let recoveryToken = result[0].recovery_token;
                console.log(data.email);
                console.log(recoveryToken);
                dynamicToken(data.email , recoveryToken).then( ()=> {
                  
                  sendEmail( { name: "Juancito", link : `localhost:3001/Frontend_Comunicados_ET32/recoverPassword/${recoveryToken}` },
                 "./test.handlebars"
                 );
                }); 
              })
            })
    });
  }catch (error) {
		console.log(error);
	}
});

let dynamicToken = (email,recoveryToken) => new Promise(function(resolve, reject){
  let sql = `select token_recovery('${email}', '${recoveryToken}', 'password', 'password')`;
  app.route(`/Frontend_Comunicados_ET32/recoverPassword/${recoveryToken}`).get(function (req, res) {
    
    try {
      pool.getConnection(function(err, connection){
          if (err) throw err;
              connection.query(sql, function (err, result) {
                if (err) throw err;
                  console.log("test");
                 res.send(result[0]);
              })
      });
    }catch (error) {
     console.log(error);
    }
  });
  resolve(sql);
});


app.route("/Frontend_Comunicados_ET32/validateSession").post(function (req, res) {
  let data = req.body;
  let sql = `SELECT bdt_cuaderno.refresh_session(${data.sessionID}, ${data.sessionEmail})`;
  try {
    pool.getConnection(function(err, connection){
        if (err) throw err;
            connection.query(sql, function (err, result) {
              if (err) throw err;
              let refreshAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
              if (refreshAccepted == 1){
                console.log("test");
                req.session.touch();
                res.send("HECHO");
              }
              console.log(result);
            })
    });
  }catch (error) {
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

                    if (err) throw err;
                    let loginAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
                    if(loginAccepted == 1) {
                      let sqlSession = `SELECT bdt_cuaderno.restrict_session("${req.sessionID}", "${data.email}")`;
                      let testVar = { sessionID: req.sessionID, status: 'success' };
                      res.json(testVar);
                      req.session.email = data.email;
                      req.session.save();
                      connection.query(sqlSession, function (err2, resulta2) {
                        if (err2) throw err2;
                        console.log(resulta2[0]);
                        let singleSession = Object.values(JSON.parse(JSON.stringify(result[0])));
                        if (singleSession == 1) {

                        }
                      });
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