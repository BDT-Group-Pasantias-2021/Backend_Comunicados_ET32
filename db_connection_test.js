/* eslint-disable eqeqeq */
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const session = require('express-session');
const database = require('./db_connection');
const mysqlsessionstore = require('./session_store');
const sendEmail = require('./email/template/send_email');
let pool = database.newPool();
let sessionStore = mysqlsessionstore.createStore();

const app = express();
const port = 3001;

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(cors());
app.use(
	session({ name: 'SessionCookie', secret: 'test', cookie: { maxAge: 600000 }, store: sessionStore, resave: true })
);

app.route('/Frontend_Comunicados_ET32/register').post(function (req, res) {
	//
	const data = req.body;
	let sql = `SELECT insert_user(${data.documento}, "${data.nombre}", "${data.apellido}", '2000-11-11', '0000000000', '1', '${data.email}', '${data.password}', '${data.confirmar_contraseña}', ${data.tipo_documento})`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let registerAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
				console.log(registerAccepted);
				console.log(JSON.parse(JSON.stringify(result[0])));
				/* res.json(registerAccepted);*/
				/* return */
				let sqlRegister = `SELECT bdt_cuaderno.login_user_node_session("${data.email}", "${data.password}")`;
				pool.getConnection(function (err, connection) {
					if (err) throw err;
					connection.query(sqlRegister, function (err, result) {
						if (err) throw err;
						let loginAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
						if (loginAccepted == 1) {
							let sqlSession = `SELECT bdt_cuaderno.restrict_session("${req.sessionID}", "${data.email}")`;

							req.session.email = data.email;
							req.session.save();
							connection.query(sqlSession, function (err2, resulta2) {
								if (err2) throw err2;
								console.log(resulta2[0]);
								let singleSession = Object.values(JSON.parse(JSON.stringify(resulta2[0])));
								if (singleSession == 1) {
									let testVar = { sessionID: req.sessionID, status: 'success' };
									res.json(testVar);
								} else {
									res.send('Ya existe una sesión para este usuario.');
								}
							});
						} else {
							res.send('Usuario o contraseña incorrectos.');
						}
						return;
					});
					connection.release();
				});
			});
		});
	} catch (error) {
		console.log(error);
	}
});

app.route('/Frontend_Comunicados_ET32/recoverPassword').post(function (req, res) {
	const data = req.body;
	let sqlRecovery = `select pass_recovery('${data.documento}', '${data.email}')`;
	let sqlTokenId = `SELECT recovery_token FROM personas where email = "${data.email}";`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sqlRecovery, function (err, result) {
				if (err) throw err;
				let isNewToken = Object.values(result[0])[0];
				if (isNewToken === '0') {
					let testVar = { status: 2 }; // 2: timeout, esperar 30m
					res.json(testVar);
					//TIMESTAMP -> ESPERAR 30 MINUTOS
					console.log('TIMESTAMP -> ESPERAR 30 MINUTOS ');
					return;
				} else {
					connection.query(sqlTokenId, function (errToken, resultGetToken) {
						if (errToken) throw errToken;
						if (resultGetToken[0] === undefined) {
							return;
						}
						console.log(resultGetToken[0]);
						let recoveryToken = resultGetToken[0].recovery_token;
						console.log(data.email);
						console.log(recoveryToken);
						process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = 0;
						getName(data.email).then((userName) => {
							console.log(userName);
							let now = new Date();
							let options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
							function addZero(i) {
								if (i < 10) {
									i = '0' + i;
								}
								return i;
							}
							let h = addZero(now.getHours());
							let m = addZero(now.getMinutes());
							let s = addZero(now.getSeconds());
							let hora = h + ':' + m + ':' + s;

							let fecha = now.toLocaleDateString('es-ES', options);
							sendEmail(
								{
									name: userName,
									hours: hora,
									date: fecha,
									link: `localhost:3000/Frontend_Comunicados_ET32?change-password=${recoveryToken}&email=${data.email}`,
								},
								'./test.handlebars',
								data.email
							);
							let testVar = { status: 1 }; //1: completado
							res.json(testVar);
						});
					});
				}
			});
		});
	} catch (error) {
		let testVar = { status: 3 };
		res.json(testVar);
		console.log(error);
	}
});

let getName = (email) =>
	new Promise(function (resolve, reject) {
		let sqlNombre = `select nombre from personas where email = '${email}'`;
		try {
			pool.getConnection(function (err, connection) {
				if (err) throw err;
				connection.query(sqlNombre, function (err, result) {
					if (err) throw err;
					let userName = result[0].nombre;
					resolve(userName);
				});
			});
		} catch (error) {
			console.log(error);
			reject(error);
		}
	});

let dynamicToken = (recoveryToken, newPass, newRePass) =>
	new Promise(function (resolve, reject) {
		let sql = `select token_recovery( '${recoveryToken}', '${newPass}', '${newRePass}')`;
		try {
			pool.getConnection(function (err, connection) {
				if (err) throw err;
				connection.query(sql, function (err, result) {
					if (err) throw err;
					console.log('test');
					resolve(result[0]);
				});
			});
		} catch (error) {
			console.log(error);
			reject(error);
		}
	});

app.route('/Frontend_Comunicados_ET32/setNewPassword').post(function (req, res) {
	let data = req.body;
	console.log('hi');
	try {
		dynamicToken(data.recovery_token, data.new_password, data.confirm_new_password).then((returnValue) => {
			console.log(returnValue);
			let isNewToken = Object.values(returnValue)[0];
			if (isNewToken == '1') {
				let response = { status: 1 }; //1: contraseña cambiada
				res.json(response);
			} else if (isNewToken == '2') {
				//returnValue 2: el token es inválido o ya ha sido usado
				let response = { status: 2 }; //3: token inválido
				res.json(response);
			}
		});
	} catch (error) {
		console.log(error);
		let response = { status: 3 }; //2: error
		res.json(response);
	}
});

app.route('/Frontend_Comunicados_ET32/validateSession').post(function (req, res) {
	let data = req.body;
	let sql = `SELECT bdt_cuaderno.refresh_session(${data.sessionID}, ${data.sessionEmail})`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let refreshAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
				if (refreshAccepted == 1) {
					console.log('test');
					req.session.touch();
					res.send('HECHO');
				}
				console.log(result);
			});
		});
	} catch (error) {
		console.log(error);
	}
});

app.route('/Frontend_Comunicados_ET32/login').post(async function (req, res) {
	const data = req.body;
	req.session.cookie.email = data.email;
	let sql = `SELECT bdt_cuaderno.login_user_node_session("${data.email}", "${data.password}")`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let loginAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
				if (loginAccepted == 1) {
					let sqlSession = `SELECT bdt_cuaderno.restrict_session("${req.sessionID}", "${data.email}")`;

					req.session.email = data.email;
					req.session.save();
					connection.query(sqlSession, function (err2, resulta2) {
						if (err2) throw err2;
						console.log(resulta2[0]);
						let singleSession = Object.values(JSON.parse(JSON.stringify(resulta2[0])));
						if (singleSession == 1) {
							let testVar = { sessionID: req.sessionID, status: 'success' };
							res.json(testVar);
						} else {
							res.send('Ya existe una sesión para este usuario.');
						}
					});
				} else {
					res.send('Usuario o contraseña incorrectos.');
				}
				return;
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

//SP SECTION search_id_tiposComunicados
app.route('/search_id_tiposComunicados').post(async function (req, res) {
	const data = req.body;
	let sql = `call search_id_tiposComunicados(${data.id});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				console.log(result)
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

//SP SECTION search_emisor_comunicados

app.route('/search_emisor_comunicados').post(async function (req, res) {
	const data = req.body;
	let sql = `call search_emisor_comunicados(${data.emisor});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				console.log(result)
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});


//SP SECTION search_fecha_comunicados
app.route('/search_fecha_comunicados').post(async function (req, res) {
	const data = req.body;
	let sql = `call search_fecha_comunicados(${data.fecha});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				console.log(result)
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

//SP SECTION search_leido_comunicados
app.route('/search_leido_comunicados').post(async function (req, res) {
	const data = req.body;
	let sql = `call search_leido_comunicados(${data.leido});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				console.log(result)
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

//SP SECTION search_titulo_comunicados
app.route('/search_titulo_comunicados').post(async function (req, res) {
	const data = req.body;
	let sql = `call search_titulo_comunicados(${data.titulo});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				console.log(result)
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

app.listen(port, () => {
	console.log(`Example app listening on port ${port}!`);
});
