const handlebars = require('handlebars');
const fs = require('fs');
const path = require('path');

const sendEmail = async (payload, template, targetEmail) => {
	let nodemailer = require('nodemailer');

	let transporter = nodemailer.createTransport({
		service: 'gmail',
		auth: {
			user: 'teamrasn@gmail.com',
			pass: 'p1t0d3c4br4',
		},
	});
	const source = fs.readFileSync(path.join(__dirname, template), 'utf8');
	const compiledTemplate = handlebars.compile(source);
	let mailOptions = {
		from: 'teamrasn@practicas.com',
		to: targetEmail,
		subject: 'Team Rasn - Practicas profesionalizantes',
		text: 'That was easy!',
		html: compiledTemplate(payload),
	};

	transporter.sendMail(mailOptions, function (error, info) {
		if (error) {
			console.log(error);
		} else {
			console.log('Email sent: ' + info.response);
		}
	});
};
module.exports = sendEmail;
