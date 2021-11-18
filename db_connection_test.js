/* eslint-disable no-unused-vars */
/* eslint-disable eqeqeq */
const variables = require('./variables');
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
const port = 3005;

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(
	cors(),
	session({
		name: 'SessionCookie',
		secret: 'test',
		cookie: { maxAge: 600000 },
		store: sessionStore,
		resave: true,
		saveUninitialized: true,
	})
);

app.route(`/${variables.baseName}/logout`).post((req, res) => {
	req.session.destroy(function (err) {
		if (err) {
			console.log(err);
		} else {
			res.send('logout');
			console.log('Session deleted');
		}
	});
	const data = req.body;
	let sql = `select ${variables.databaseName}.destroy_session(${data.sessionID});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let isDeleted = Object.values(result[0])[0];
				if (isDeleted == 1) {
					console.log('Session deleted');
				} else {
					console.log('Session not deleted');
				}
			});
		});
	} catch (error) {
		console.log(error);
	}
});

app.route(`/${variables.baseName}/register`).post(function (req, res) {
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
				let sqlRegister = `SELECT ${variables.databaseName}.login_user_node_session("${data.email}", "${data.password}")`;
				pool.getConnection(function (err, connection) {
					if (err) throw err;
					connection.query(sqlRegister, function (err, result) {
						if (err) throw err;
						let loginAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
						if (loginAccepted == 1) {
							let sqlSession = `SELECT ${variables.databaseName}.restrict_session("${req.sessionID}", "${data.email}")`;

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

app.route(`/${variables.baseName}/recoverPassword`).post(function (req, res) {
	const data = req.body;
	let sqlRecovery = `SELECT pass_recovery('${data.documento}', '${data.email}')`;
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
									link: `${variables.host}:${variables.frontendPort}?change-password=${recoveryToken}&email=${data.email}`,
								},
								'/test.handlebars',
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

app.route(`/${variables.baseName}/setNewPassword`).post(function (req, res) {
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

app.route(`/${variables.baseName}/validateSession`).post(function (req, res) {
	let data = req.body;
	let sql = `SELECT ${variables.databaseName}.refresh_session(${data.sessionID}, ${data.sessionEmail})`;
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

app.route(`/${variables.baseName}/login`).post(async function (req, res) {
	const data = req.body;
	req.session.cookie.email = data.email;
	let sql = `SELECT ${variables.databaseName}.login_user_node_session("${data.email}", "${data.password}")`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let loginAccepted = Object.values(JSON.parse(JSON.stringify(result[0])));
				if (loginAccepted == 1) {
					let sqlSession = `SELECT ${variables.databaseName}.restrict_session("${req.sessionID}", "${data.email}")`;

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
app.route(`/${variables.baseName}/search_id_tiposComunicados`).post(async function (req, res) {
	const data = req.body;
	let sql = `call search_id_tiposComunicados(${data.id});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let miArray = fixSearchResults(result[0]);
				miArray.forEach((element) => {
					console.log('---------');
					element.comunicados = groupEtiquetas(element.comunicados);
					console.log(element.comunicados);
				});
				res.json(miArray);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

//SP SECTION search_emisor_comunicados

app.route(`/${variables.baseName}/search_emisor_comunicados`).post(async function (req, res) {
	const data = req.body;
	let sql = `call search_emisor_comunicados(${data.emisor});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let miArray = fixSearchResults(result[0]);
				miArray.forEach((element) => {
					console.log('---------');
					element.comunicados = groupEtiquetas(element.comunicados);
					console.log(element.comunicados);
				});
				res.json(miArray);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

//SP SECTION search_emisor_comunicados
app.route(`/${variables.baseName}/search_receptor_comunicados`).post(async function (req, res) {
	const data = req.body;
	let sql = `call search_receptor_comunicados(${data.email});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let miArray = fixSearchResults(result[0]);
				miArray.forEach((element) => {
					console.log('---------');
					element.comunicados = groupEtiquetas(element.comunicados);
					console.log(element.comunicados);
				});
				res.json(miArray);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

//SP SECTION search_fecha_comunicados
app.route(`/${variables.baseName}/search_fecha_comunicados`).post(async function (req, res) {
	const data = req.body;
	let sql = `call search_fecha_comunicados(${data.fecha});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let miArray = fixSearchResults(result[0]);
				miArray.forEach((element) => {
					console.log('---------');
					element.comunicados = groupEtiquetas(element.comunicados);
					console.log(element.comunicados);
				});
				res.json(miArray);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

//SP SECTION search_leido_comunicados
app.route(`/${variables.baseName}/search_leido_comunicados`).post(async function (req, res) {
	const data = req.body;
	let sql = `call search_leido_comunicados(${data.leido});`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let miArray = fixSearchResults(result[0]);
				miArray.forEach((element) => {
					console.log('---------');
					element.comunicados = groupEtiquetas(element.comunicados);
					console.log(element.comunicados);
				});
				res.json(miArray);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

//SP SECTION search_titulo_comunicados
app.route(`/${variables.baseName}/search_titulo_comunicados`).post(async function (req, res) {
	const data = req.body;
	let sql = `call search_titulo_comunicados('${data.titulo}');`;
	/* let sql = `call search_titulo_comunicados("");`; */
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;
				let miArray = fixSearchResults(result[0]);
				miArray.forEach((element) => {
					element.comunicados = groupEtiquetas(element.comunicados);
				});
				res.json(miArray);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

app.route(`/${variables.baseName}/insertComunicado`).post(async function (req, res) {
	const data = req.body;
	// let sql = `SELECT ${variables.databaseName}.insert_comunicado(${data.emisor}, "${data.titulo}", "${data.descripcion}", ${data.cursoReceptor});`;
	let sql = `SELECT ${variables.databaseName}.insert_comunicado(10000, "ttttti", "titttt", 2)`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;

				let queryResult = Object.values(JSON.parse(JSON.stringify(result[0])));

				//1: realizado, 2: emisor no existe, 3: título entre 5 y 50 caracteres, 4: descripcion de al menos 5, 5: curso no existe
				let response = { status: parseInt(queryResult) };
				res.json(response);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

app.route(`/${variables.baseName}/deleteComunicado`).post(async function (req, res) {
	const data = req.body;
	// let sql = `SELECT ${variables.databaseName}.delete_comunicado(${data.idComunicado});`;
	let sql = `SELECT ${variables.databaseName}.delete_comunicado(18)`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;

				let queryResult = Object.values(JSON.parse(JSON.stringify(result[0])));

				//1: realizado, 2: comunicado no existe
				let response = { status: parseInt(queryResult) };
				res.json(response);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

app.route(`/${variables.baseName}/addCategoriaComunicado`).post(async function (req, res) {
	const data = req.body;
	// let sql = `SELECT ${variables.databaseName}.add_categoria_comunicado(${data.idComunicado}, ${data.idCategoria});`;
	let sql = `SELECT ${variables.databaseName}.add_categoria_comunicado(17, 5)`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;

				let queryResult = Object.values(JSON.parse(JSON.stringify(result[0])));

				//1: realizado, 2: categoría no existe, 3: comunicado no existe
				let response = { status: parseInt(queryResult) };
				res.json(response);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

app.route(`/${variables.baseName}/deleteCategoriaComunicado`).post(async function (req, res) {
	const data = req.body;
	// let sql = `SELECT ${variables.databaseName}.delete_categoria_comunicado(${data.idComunicado}, ${data.idCategoria});`;
	let sql = `SELECT ${variables.databaseName}.delete_categoria_comunicado(1, 333)`;
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;

				let queryResult = Object.values(JSON.parse(JSON.stringify(result[0])));

				//1: realizado, 2: categoría no existe, 3: comunicado no existe
				let response = { status: parseInt(queryResult) };
				res.json(response);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

app.route(`/${variables.baseName}/firmarComunicado`).post(async function (req, res) {
	const data = req.body;
	let sql = `SELECT ${variables.databaseName}.firmar_comunicado(${data.idComunicado}, ${data.email});`;
	/* let sql = `SELECT ${variables.databaseName}.firmar_comunicado(17, 1);`; */
	try {
		pool.getConnection(function (err, connection) {
			if (err) throw err;
			connection.query(sql, function (err, result) {
				if (err) throw err;

				let queryResult = Object.values(JSON.parse(JSON.stringify(result[0])));

				//1: realizado, 2: usuario no existe, 3: comunicado no existe
				let response = { status: parseInt(queryResult) };
				res.json(response);
			});
			connection.release();
		});
	} catch (error) {
		console.log(error);
	}
});

// Agrupar objetos con el mismo id y juntar sus etiquetas
const groupEtiquetas = (finalArray) => {
	let groupedArray = [];
	finalArray.forEach((element) => {
		let index = groupedArray.findIndex((x) => x.id_comunicaciones === element.id);
		let tempEtiqueta = {
			id_etiqueta: element.id_categoria,
			receptor: element.receptor,
			etiqueta: element.etiqueta,
			color: element.color,
		};

		if (element.id_categoria == null || element.id_categoria == undefined) {
			groupedArray.push({
				id_comunicaciones: element.id,
				fecha: element.fecha,
				titulo: element.titulo,
				emisor: element.emisor,
				descripcion: element.descripcion,
				leido: !!element.leido,
				receptor: element.receptor,
			});
		} else if (index === -1) {
			groupedArray.push({
				id_comunicaciones: element.id,
				fecha: element.fecha,
				titulo: element.titulo,
				emisor: element.emisor,
				descripcion: element.descripcion,
				leido: !!element.leido,
				receptor: element.receptor,
				etiquetas: [tempEtiqueta],
			});
		} else {
			groupedArray[index].etiquetas.push(tempEtiqueta);
		}
	});
	console.log(groupedArray);
	return groupedArray;
};
// Group objects by attribute fecha and return an array of objects with the same fecha
const fixSearchResults = (resultArray) => {
	let groupBy = (array, key) => {
		return array.reduce(function (rv, x) {
			(rv[x[key]] = rv[x[key]] || []).push(x);
			return rv;
		}, {});
	};

	let grouped = groupBy(resultArray, 'fecha');

	let finalResult = [];

	for (let key in grouped) {
		let obj = {};
		obj.fecha = key;
		obj.comunicados = grouped[key];
		finalResult.push(obj);
	}
	return finalResult;
};

app.listen(port, () => {
	console.log(`Example app listening on port ${port}!`);
	console.log(variables.databaseName);
});
