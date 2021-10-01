-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 01-10-2021 a las 22:27:28
-- Versión del servidor: 10.4.19-MariaDB
-- Versión de PHP: 8.0.7

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bdt_cuaderno`
--

DELIMITER $$
--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `change_pass` (`_emailUser` VARCHAR(250), `_oldPass` VARCHAR(250), `_newPass` VARCHAR(250), `_newRePass` VARCHAR(250)) RETURNS TEXT CHARSET utf8 BEGIN
	DECLARE _message TEXT;
    SET _message = '';
    SET @coincide := (select `id_persona` from `persona` where `email` = _emailUser and `password` = md5(_oldPass) );
    if (@coincide > 0 ) THEN
        if(_newPass = _newRePass) THEN
            IF(_oldPass != _newPass ) THEN
                IF (length(_newPass) >= 5  AND length(_newPass) <= 25) THEN
                    UPDATE `persona` SET `password` = md5(_newPass) WHERE `id_persona` =  @coincide;
                    SET _message = 'Su contraseña se modificó correctamente';
                ELSE
                    SET _message = 'La contraseña no cumple con los párametros. Mayor a 5 y menor a 25 caracteres.';
                END IF;
            ELSE
                SET _message = 'Ingrese una contraseña NUEVA (distina a la anterior).';
            END IF;
        ELSE
            SET _message = 'Las contraseñas no coinciden';
        END IF; 
    ELSE
        SET _message = 'Este usuario no se encuentra registrado en la base de datos.';
    END IF;
    RETURN _message;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_age_user` (`_idPersona` INT(10)) RETURNS INT(10) BEGIN
	declare ageUser int(10);
    set ageUser := (SELECT YEAR(CURDATE())-YEAR(fecha_nac) + IF(DATE_FORMAT(CURDATE(),'%m-%d') > DATE_FORMAT(fecha_nac,'%m-%d'), 0 , -1 ) AS `EDAD_ACTUAL` 
    FROM personas
    where id_persona = _idPersona);
RETURN ageUser;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `insert_user` (`_documentUser` VARCHAR(255), `_name` VARCHAR(250), `_lastName` VARCHAR(250), `_birthDate` DATE, `_phoneNumber` VARCHAR(50), `_category` INT, `_email` VARCHAR(250), `_password` TEXT, `_confirmPassword` TEXT, `_typeDocument` INT) RETURNS TEXT CHARSET utf8 BEGIN
    DECLARE _message TEXT;
    SET _message = '';
	IF (length(_documentUser ) > 0) THEN
		IF(EXISTS (SELECT * FROM `tipos_documento` WHERE (`tipos_documento`.`id_tipos_documento` = _typeDocument))) THEN
			IF (NOT EXISTS(SELECT * FROM `personas` WHERE (`personas`.`documento` = _documentUser)) AND NOT EXISTS(SELECT * FROM `personas` WHERE (`personas`.`email` = _email))) THEN
				IF (_name IS NOT null AND _name <> '' AND length(_name) >= 2) THEN
					IF (_lastName IS NOT null AND _lastName <> '' AND length(_lastName) >= 2) THEN
						IF(TIMESTAMPDIFF( YEAR,_birthDate, CURDATE()) >= 12) THEN
							IF(EXISTS (SELECT * FROM `categorias` WHERE (`categorias`.`categoria_id` = _category))) THEN
								IF (_email IS NOT null AND _email <> '') THEN
									IF (LOCATE('@', _email) AND LOCATE('.', _email) AND length(_email) > 5) THEN 
										IF (length(_documentUser) <= max_chars_document(_typeDocument)) THEN
											IF (length(_password) >= 5  AND length(_password) <= 25) THEN
												IF (_password = _confirmPassword ) THEN 
													INSERT INTO `personas` (`documento`, `nombre`, `apellido`, `fecha_nac`, `telefono`, `categoria`, `email`, `password`, `tipo_documento`) VALUES ( _documentUser, _name, _lastName, _birthDate, _phoneNumber, _category, _email, md5(_password), _typeDocument);
													SET _message = 'Se ha agregado satisfactoriamente';
												ELSE
													SET _message = 'Contraseña incorrecta';
												END IF;
											ELSE
												SET _message = 'Ingrese una contraseña mayor a 5 y menor a 25 caracteres';
											END IF;
										ELSE
											SET _message = 'El documento ingresado no concuerda con el tipo de documento.';
										END IF; 
									ELSE
										SET _message = 'Ingrese un email valido';
									END IF;
								ELSE
									SET _message = 'Ingrese el email';
								END IF;
							ELSE
								SET _message = 'Esta categoría no existe';
							END IF;
						ELSE
							SET _message = 'Fecha inválida';
						END IF;
					ELSE 
						SET _message = 'Ingrese un apellido real';
					END IF;
				ELSE
					SET _message = 'Ingrese un nombre real';
				END IF;
			ELSE
				SET _message = 'El usuario ya se encuentra registrado';
			END IF;
		ELSE
			SET _message = "Este tipo de documento no existe";
		END IF;
	ELSE
		SET _message = 'El documento esta vacio';
	END IF; 
    RETURN _message;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `login_user` (`_emailUser` VARCHAR(255), `_passUser` VARCHAR(255)) RETURNS VARCHAR(255) CHARSET latin1 COLLATE latin1_general_ci BEGIN
    declare _token text;
    declare _user_id text;
    SET _user_id := (select documento from personas where email = _emailUser and password = _passUser);
    set _token = "invalid-user";
    IF EXISTS (select documento from personas where email = _emailUser and password = _passUser) THEN
        set _token = sha2("abc",224);
            return _token;
        ELSE
            return _token;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `login_user_node_session` (`_emailUser` VARCHAR(255), `_passUser` VARCHAR(255)) RETURNS VARCHAR(255) CHARSET latin1 COLLATE latin1_general_ci BEGIN
    declare _token text;
    declare _user_id text;
    SET _user_id := (select documento from personas where email = _emailUser and password = md5(_passUser));
    set _token = 0;
    IF EXISTS (select documento from personas where email = _emailUser and password = md5(_passUser)) THEN
        set _token = 1;
            return _token;
        ELSE
            return _token;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `max_chars_document` (`_tipoDocumento` INT) RETURNS INT(11) BEGIN
	CASE
		WHEN _tipoDocumento = 1 THEN RETURN 8;
        WHEN _tipoDocumento = 2 THEN RETURN 9;
        WHEN _tipoDocumento  = 3 THEN RETURN 8; 
        ELSE RETURN 10;
	END CASE;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `pass_recovery` (`_documentUser` INT(10), `_emailUser` VARCHAR(250)) RETURNS TEXT CHARSET latin1 COLLATE latin1_general_ci BEGIN
	DECLARE _message TEXT;
    DECLARE _token TEXT;
    DECLARE _timestamp DATETIME;
    
    SET _message = '';
    set @lastRecovery := (SELECT (last_recovery) FROM `personas` WHERE `email` = _emailUser and `documento` = _documentUser);
    SET @existe := (SELECT count(*) FROM `personas` WHERE `email` = _emailUser and `documento` = _documentUser);
    IF (LOCATE('@', _emailUser) AND LOCATE('.', _emailUser) AND LENGTH(_emailUser) > 5) THEN
      IF (@existe > 0) THEN
		if not exists(SELECT (last_recovery) FROM `personas` WHERE `email` = _emailUser and `documento` = _documentUser) THEN
			SET _message = "1";
			SET _token = LEFT(MD5(RAND()), 20);
			update `personas` SET `recovery_token` = _token, `last_recovery` = now() where documento = _documentUser and email = _emailUser;
		ELSE
			if (TIMESTAMPDIFF(SECOND, @lastRecovery, now() ) < 30) THEN
				SET _message = "0";
			ELSE 
				SET _message = "1";
				SET _token = LEFT(MD5(RAND()), 20);
				update `personas` SET `recovery_token` = _token, `last_recovery` = now() where documento = _documentUser and email = _emailUser;
            END IF;
        END IF;
    ELSE
        SET _message = "Los datos ingresados no corresponden a ningun registro";
      END IF;
    ELSE
      SET _message = "El email ingresado NO cumple con las caracteristicas correspondientes";
    END IF;
RETURN _message;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `refresh_session` (`_sessionID` VARCHAR(128), `_userEmail` VARCHAR(128)) RETURNS TEXT CHARSET latin1 COLLATE latin1_general_ci BEGIN
	IF EXISTS(SELECT * FROM personas WHERE email = _userEmail AND ultima_sesion = _sessionID) THEN
		RETURN 1;
        ELSE 
        RETURN 0;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `restrict_session` (`_sessionID` VARCHAR(128), `_emailUser` VARCHAR(255)) RETURNS VARCHAR(1122) CHARSET latin1 COLLATE latin1_general_ci BEGIN

	IF ((SELECT ultima_sesion FROM personas WHERE email = _emailUser) IS NULL) THEN
		DO SLEEP(2);
		UPDATE `bdt_cuaderno`.`personas` SET `ultima_sesion` = _sessionID WHERE `email` = _emailUser;
        RETURN 1;
	END IF;
    RETURN 0;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `token_recovery` (`_emailUser` VARCHAR(250), `_token` TEXT, `_newPass` VARCHAR(250), `_newRePass` VARCHAR(250)) RETURNS TEXT CHARSET utf8 BEGIN
	DECLARE _message TEXT;
    SET _message = '';
    SET @coincide := (select `id_persona` from `personas` where `email` = _emailUser and `recovery_token` = _token);
    
    if (@coincide > 0 ) THEN
        if(_newPass = _newRePass) THEN
                IF (length(_newPass) >= 5  AND length(_newPass) <= 25) THEN
                    UPDATE `personas` SET `password` = md5(_newPass), `recovery_token` = null WHERE `id_persona` =  @coincide;
					
                    SET _message = 'Su contraseña se modificó correctamente';
                ELSE
                    SET _message = 'La contraseña no cumple con los párametros. Mayor a 5 y menor a 25 caracteres.';
                END IF;
        ELSE
            SET _message = 'Las contraseñas no coinciden';
        END IF; 
    ELSE
        SET _message = 'Este token ya no es válido.';
    END IF;
    RETURN _message;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `trimestre_actual` (`_date` DATE) RETURNS INT(11) BEGIN
	IF (MONTH(_date) BETWEEN MONTH("2021-03-01") AND MONTH("2021-05-31")) THEN
		RETURN 1;
	ELSE IF (MONTH(_date) BETWEEN MONTH("2021-06-01") AND MONTH("2021-08-31")) THEN
		RETURN 2;
	ELSE IF (MONTH(_date) BETWEEN MONTH("2021-09-01") AND MONTH("2021-11-30")) THEN
		RETURN 3;
	ELSE 
		RETURN 0;
            END IF;
		END IF;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `asistencia`
--

CREATE TABLE `asistencia` (
  `persona` int(10) NOT NULL,
  `fecha` date NOT NULL,
  `turno` char(1) COLLATE latin1_general_ci NOT NULL,
  `asistio` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `asistencia`
--

INSERT INTO `asistencia` (`persona`, `fecha`, `turno`, `asistio`) VALUES
(1, '0000-00-00', '[', 0),
(1, '0000-00-00', '[', 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `categoria_id` int(11) NOT NULL,
  `nombre_cat` varchar(30) COLLATE latin1_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`categoria_id`, `nombre_cat`) VALUES
(1, 'alumno'),
(2, 'docente'),
(3, 'preceptor'),
(4, 'directivo'),
(5, 'tutor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `comunicaciones`
--

CREATE TABLE `comunicaciones` (
  `id_comunicaciones` int(11) NOT NULL,
  `fecha` date NOT NULL,
  `receptor` int(11) NOT NULL,
  `emisor` int(11) NOT NULL,
  `titulo` varchar(100) COLLATE latin1_general_ci NOT NULL,
  `descripcion` text COLLATE latin1_general_ci NOT NULL,
  `leido` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `comunicaciones`
--

INSERT INTO `comunicaciones` (`id_comunicaciones`, `fecha`, `receptor`, `emisor`, `titulo`, `descripcion`, `leido`) VALUES
(1, '2021-09-09', 2, 1, 'Hola', 'Holaaa', 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cursos`
--

CREATE TABLE `cursos` (
  `id_curso` int(11) NOT NULL,
  `anio` int(1) NOT NULL,
  `division` int(1) NOT NULL,
  `turno` char(1) COLLATE latin1_general_ci NOT NULL,
  `especialidad` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `cursos`
--

INSERT INTO `cursos` (`id_curso`, `anio`, `division`, `turno`, `especialidad`) VALUES
(1, 6, 1, 'M', 1),
(2, 5, 1, 'T', 1),
(3, 4, 4, 'V', 2),
(4, 4, 5, 'V', 3);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `curso_materia`
--

CREATE TABLE `curso_materia` (
  `curso` int(11) NOT NULL,
  `materia` int(11) NOT NULL,
  `horario` datetime NOT NULL,
  `especialidad` int(11) NOT NULL,
  `profesor` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `datos_escolares`
--

CREATE TABLE `datos_escolares` (
  `titulo` varchar(50) COLLATE latin1_general_ci NOT NULL,
  `descripcion` text COLLATE latin1_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `datos_escolares`
--

INSERT INTO `datos_escolares` (`titulo`, `descripcion`) VALUES
('codigo_de_vestimenta', 'No utilizar bermudas en taller.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `especialidades`
--

CREATE TABLE `especialidades` (
  `id_especialidad` int(11) NOT NULL,
  `nombre_esp` varchar(50) COLLATE latin1_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `especialidades`
--

INSERT INTO `especialidades` (`id_especialidad`, `nombre_esp`) VALUES
(1, 'computacion'),
(2, 'mecanica'),
(3, 'automotores');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `evaluaciones`
--

CREATE TABLE `evaluaciones` (
  `id_evaluaciones` int(11) NOT NULL,
  `materia` int(11) NOT NULL,
  `alumno` int(11) NOT NULL,
  `nota` float NOT NULL,
  `fecha` date NOT NULL,
  `descripcion` text COLLATE latin1_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `evaluaciones`
--

INSERT INTO `evaluaciones` (`id_evaluaciones`, `materia`, `alumno`, `nota`, `fecha`, `descripcion`) VALUES
(1, 6, 7, 10, '2021-09-14', 'Prueba sobre Límites y Continuidad.'),
(2, 6, 8, 6, '2021-09-21', 'Prueba sobre Derivadas'),
(3, 6, 4, 5, '2021-03-27', 'Prueba sobre Funciones'),
(4, 7, 8, 10, '2021-03-27', 'Prueba sobre algo industrial'),
(5, 8, 1, 1, '2021-03-27', 'Debate con Ramiro'),
(6, 8, 1, 1, '2020-03-27', 'Debate con Ramiro');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `materias`
--

CREATE TABLE `materias` (
  `id_materia` int(11) NOT NULL,
  `nombre_mat` varchar(50) COLLATE latin1_general_ci NOT NULL,
  `anio` int(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `materias`
--

INSERT INTO `materias` (`id_materia`, `nombre_mat`, `anio`) VALUES
(1, 'matematica', 1),
(2, 'matematica', 2),
(3, 'matematica', 3),
(4, 'matematica', 4),
(5, 'matematica', 5),
(6, 'matematica', 6),
(7, 'GPP', 6),
(8, 'Ciudadanía y Trabajo', 6);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `materias_adeudadas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `materias_adeudadas` (
`Promedio` double
,`Materia` varchar(50)
,`Año` int(1)
,`Trimestre` int(11)
,`Alumno` int(11)
,`Año_de_cursada` int(4)
);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personas`
--

CREATE TABLE `personas` (
  `id_persona` int(11) NOT NULL,
  `documento` int(10) NOT NULL,
  `nombre` varchar(30) COLLATE latin1_general_ci NOT NULL,
  `apellido` varchar(30) COLLATE latin1_general_ci NOT NULL,
  `fecha_nac` date NOT NULL,
  `telefono` varchar(30) COLLATE latin1_general_ci NOT NULL,
  `categoria` int(11) NOT NULL,
  `email` varchar(30) COLLATE latin1_general_ci NOT NULL,
  `password` varchar(300) COLLATE latin1_general_ci NOT NULL,
  `tipo_documento` int(11) NOT NULL,
  `foto_perfil` varchar(255) COLLATE latin1_general_ci NOT NULL,
  `ultima_sesion` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `recovery_token` text COLLATE latin1_general_ci DEFAULT NULL,
  `last_recovery` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `personas`
--

INSERT INTO `personas` (`id_persona`, `documento`, `nombre`, `apellido`, `fecha_nac`, `telefono`, `categoria`, `email`, `password`, `tipo_documento`, `foto_perfil`, `ultima_sesion`, `recovery_token`, `last_recovery`) VALUES
(1, 44561985, 'Juan Pablo', 'Aubone', '2003-01-29', '1168407520', 1, 'juanaubone@gmail.com', '5f4dcc3b5aa765d61d8327deb882cf99', 1, '', NULL, '1baf83024a53fb97d769', '2021-10-01 17:20:19'),
(2, 0, 'Ke', 'Ke', '2003-12-12', '11111111111111111', 5, 'm3eee3nem@fakemdenem33.m', '9530b5d1a1b662e1c02d882649fc70c6', 1, '', NULL, NULL, NULL),
(3, 0, 'Ke', 'Ke', '2003-12-12', '11111111111111111', 5, 'meeee3nem@fakemdenem33.m', '9530b5d1a1b662e1c02d882649fc70c6', 2, '', NULL, NULL, NULL),
(4, 0, 'Ke', 'Ke', '2003-12-12', '11111111111111111', 5, 'meeeenem@fakemdenem33.m', 'e6b376d1ecc828f16904a4f808b4ab2f', 1, '', NULL, NULL, NULL),
(5, 0, 'Carlos', 'Menem', '2003-03-12', '11111111111111111', 1, 'meeeenem@fakemenem.m', 'e6b376d1ecc828f16904a4f808b4ab2f', 1, '', NULL, NULL, NULL),
(6, 0, 'Ke', 'Ke', '2003-12-12', '11111111111111111', 1, 'meeeenem@fakemenem33.m', 'e6b376d1ecc828f16904a4f808b4ab2f', 1, '', NULL, NULL, NULL),
(7, 0, 'Carlos', 'Menem', '2003-03-12', '11111111111111111', 1, 'menem@menem.menem', 'e6b376d1ecc828f16904a4f808b4ab2f', 1, '', NULL, NULL, NULL),
(8, 0, 'Samuel', 'Hernández', '2003-03-27', '91121678328', 1, 'sdho2003@gmail.com', '5f4dcc3b5aa765d61d8327deb882cf99', 1, '', NULL, NULL, NULL),
(9, 95825635, 'Samuel', 'Hernández', '2003-03-27', '1121678328', 1, 'sdho2023@gmail.com', 'e9a0372306ec126b3288e8ed32ced84e', 2, '', NULL, NULL, NULL),
(11, 95825655, 'Samuel', 'Hernández', '2000-11-11', '0000000000', 1, 'sdho2011@gmail.com', '640e5a3b9f9e4d667456c4e68194d6a2', 1, '', NULL, NULL, NULL),
(12, 95858655, 'Samuel', 'Hernández', '2000-11-11', '0000000000', 1, 'sdho203333@gmail.com', '640e5a3b9f9e4d667456c4e68194d6a2', 1, '', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `persona_curso`
--

CREATE TABLE `persona_curso` (
  `persona` int(11) NOT NULL,
  `curso` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `persona_curso`
--

INSERT INTO `persona_curso` (`persona`, `curso`) VALUES
(1, 1),
(1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sessions`
--

CREATE TABLE `sessions` (
  `session_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `session_expires` int(11) UNSIGNED NOT NULL,
  `session_data` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `sessions`
--

INSERT INTO `sessions` (`session_id`, `session_expires`, `session_data`) VALUES
('-a1kdEmjWLvzp_wYnFHycKOVoEINvXg7', 1633119810, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:30.392Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('0CRanpQfdsiZjIghOkr8y2Tj91NorfZA', 1633119924, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:23.605Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('0rmyJYCXRWHeMRKFE46EYxDRXHBTU0_D', 1633119924, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:23.602Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('1Gy20dGnKbUPI17RgSl36iaiBBtDX8-M', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.548Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('1ViOrwwdSfQQfh3MNeOqcS7cG6SXh00R', 1633119849, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:24:08.565Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('1YfXdlzzRP7fqv7jFE1qOj9ohcHaZJu9', 1633119810, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:30.350Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('1uSgS2LFpA-yhoOVNQeuqwnrqRTVScIg', 1633119761, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:40.725Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('36pGtWHMDdt98O6xsVGsJ_BCInkFV3YJ', 1633119810, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:30.348Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('3Uq00tchX7yR5EJtpRb8NSZyL8AxHjtW', 1633119761, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:40.823Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('3XD036IE759osJgtzghXcNJOZZhcIBRt', 1633119798, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:17.951Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('55jyOjYMWIclXZIsU7Ju5QcK3x-LnPfR', 1633119923, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:23.457Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('6bhSVkWALVhnPCdJKJbPX4NTCFZw6aGW', 1633119838, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:57.692Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('7PQeNA01Zp3S-0sWm2d74BRu_vqJbuut', 1633119923, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:23.352Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('7QVgXvlZkHoToKigAgDxRFsMrWHXtqI8', 1633119840, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:24:00.046Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('9EdslkJyTEACBkko3HWG8qEqWSytNXG7', 1633119810, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:30.345Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('AGmzXY4qIYt4A1V2AN972ExiPSYFp4-j', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.655Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('AJy41TxNAOb-AZZg8whsNnzb3NQXolZo', 1633119798, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:18.285Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('BTl1HA0MxNm9nCnVU66CVB8tICIERaQb', 1633119761, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:40.792Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('BuyGkC-SyDl-kFsZ2-TFd5duNAM14wMW', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.652Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('D6-3-bc28QDT5GXxxvm0GzePCcXzydcR', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.536Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('DMGnz2NA1shLrVxrtnAtbDcZbqiAo7mz', 1633119761, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:40.730Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('DWFWOjm1TcCGYwHvFwpKpatzq8-8kbK9', 1633119725, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:05.064Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('Dnhg7l1Syk0rQUi385zmPyO91XX481Ax', 1633119810, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:30.336Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('EPKcqKt4YR31K9HVz24FYWShC3ZtBtF8', 1633119913, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:13.327Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('EoWuQDdHWSb5c5lGqSra_Q-LQDYCMyJf', 1633119810, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:30.352Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('FDeaJhrH8cys-QnwH04WiNN0atEvK_o9', 1633119913, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:13.263Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('GwcKrQCLvo552PWffkFbU_-Nelb42kPM', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.688Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('HrwSsakDOEtcOuAy0_aP173C6FBceApD', 1633119913, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:13.237Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('JLW_sFpviTFSfQZAbnrzlVuVgSqKgXWS', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.608Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('JW7vEtXhppRMHjBYeFZR6ko-nVWW7tmv', 1633120188, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:29:47.537Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('Jc4l7NRKx7IkyfLCTEUXWgQY9nl2uY_s', 1633119761, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:40.717Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('KPeVAzYuik4bXTyZ8-l1WMMhMdVwGrSB', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.724Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('KwynaeNmg9BV3oBeDS37JY_qgXUkLq1_', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.514Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('LCIXlZwV5dwxUzupPAADF6gyP092ruaa', 1633119924, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:23.607Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('Lw8xoPittCyBcCHTilepRCy8-MGMoLxK', 1633119761, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:40.726Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('MZ6gWBHv9MNqCsJlJPGbQeWjVB146eEA', 1633119798, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:17.936Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('Mcr-mHHhfjKb5PpGTpY5utDNtCrg4tEQ', 1633119913, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:13.258Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('OhvQ28xhKD-Uv5fZdibe6MeNYxJDJpeb', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.538Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('PAY0zJg10liNV_5PHfkd6zXKNDKDIwpq', 1633119725, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:04.838Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('PQGYvqHckQ-gca8zvBwKW2Id5fRlLr0v', 1633119798, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:18.209Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('P_BS_GohmqYaomR3I3IEzF16NnKLpMhF', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.550Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('QgX7tQM8Mg8y6foZuyA8WPOgL1KPUPRJ', 1633119725, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:04.868Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('R1IsTbovkjKOpPebeSttiHlpQGezEQpL', 1633119852, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:24:12.466Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('R1aCWU5YU0tcwOMK7Uh6CywOGQZL6DNP', 1633119798, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:17.953Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('RcGUwmk-pF5K9vz8QpeWyL3XnJGNJjVG', 1633119924, '{\"cookie\":{\"originalMaxAge\":599999,\"expires\":\"2021-10-01T20:25:23.599Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('SmxfCXbc7IvGZl5BfW0iu1X4DagCRchB', 1633119798, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:18.012Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('TrSLcAgIHyHi6DsPQRQYXiNsE5nWFfuB', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.541Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('UBmILV2bIvYgcZ02Ly6uL-mm_zElLu9z', 1633119725, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:04.834Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('UMwNjtgNpYv1p5yl0BFp1s2EyRETrJiB', 1633119913, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:13.397Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('UYBNLtv5jYdEzJzBhEOX8O2IL3vG3BOG', 1633119913, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:13.267Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('VIBgvTzVw_EOBF8sn8iDQQ0QfmWrEUct', 1633119855, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:24:14.507Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('VJgDtFrwHSSx3_v7pb9C9G9aom26Kx-K', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.591Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('Wdz9LNYoj_ur0HkiL_FdO7a3druf5yjU', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.559Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('Y1gxWaH3qEn3p08Dhj_MeU-SBbnxp6Ci', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.779Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('ZMtnZlKgWBU_QJxmQXZzihtc1_hNQ17m', 1633119924, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:23.604Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('ZRZLVV5RRklzMZu8MA6AvbOq_wKGQq6j', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.758Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('_vI9djCMhrbWKIshKMx-zexjLizW7AzW', 1633119858, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:24:17.731Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('aK8UFk8rhj8yDOSB98lrm6p_1FN02Srf', 1633119810, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:30.448Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('aTPmSG_ur2UmTacslFOCzmg53CGfFkpD', 1633119836, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:56.024Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('cphzRmr-N6ftOJJG85gppP1OrufUNP9Q', 1633119761, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:40.728Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('d5CmlxEF-RxEXL2RClRqdy84oIl2xqHP', 1633119851, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:24:10.913Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('dG2JK3vr0TVGNnSdYvZxb28tistTsEm5', 1633119913, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:13.355Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('f-bI1rWDi0lqpIG_IXNxNGQsywBzS0M-', 1633119856, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:24:16.095Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('f7QebVdIuLuypSzIrT9M3hyz049Evtlx', 1633119801, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:20.617Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('fKTHGPojoUhBKD3jYc55U4OzbTafJyZu', 1633119810, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:30.425Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('fthHbdWL6f43SVyv_lcEQQ-xndJgOLge', 1633119798, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:17.946Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('ggc6oYYJGJMTOA6-QRb51hMJA-8CHIuk', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.591Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('hZPCo7aAUI6Sx9n1WJQ_UOUhoqcJXSaJ', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.605Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('hy-f0dQFL9y7CIp2MS64T7ZZ1gsxkQXr', 1633119923, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:23.399Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('iDrYKwXnft87IvdowK1R9OB37qZ4Vpbw', 1633119913, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:13.377Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('ihXjiuK3eZamQvOyQx25twWK8Ya0MgnW', 1633119798, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:18.043Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('jEBzLMn1p__SvyHcU7ZYUtyIIEJPAG-5', 1633119725, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:05.102Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('l5aJK67fORwgS0-LLFTRqHhAhojn7dRq', 1633119923, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:23.486Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('nYhvrOnkXuu_mgP6VaiQ2uRta006bJK0', 1633119913, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:13.261Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('pMjQ8WsffDIjrOJBP2WiYamt-8aM8GvM', 1633119810, '{\"cookie\":{\"originalMaxAge\":599999,\"expires\":\"2021-10-01T20:23:30.466Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('r31VMeox_DAgM9f6eXPoVp3_AhBODdjl', 1633119761, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:40.918Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('r_1C1zFDmAe0yBpeCCNcVeIpSsUMZHDh', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.602Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('sRSZR1H78w-J0QpjL-vKpJ2CmGQDTOAQ', 1633119810, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:30.344Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('tRhftZNgQogKX5pdD0QbVxNqoxTVQDkZ', 1633119761, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:40.919Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('tYq6RhkjHZUbOxE7SNx5QXtm6GQXxQPK', 1633119725, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:04.837Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('uMS8zMVc72ykBt7W18QvbZ6mq_E_R0KL', 1633119725, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:04.828Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('vNJ01lnV_zjtn49Ty9X_exnlHRZ6v63l', 1633119798, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:17.949Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('wGKtmXECCYlC5xvsIEnN1l82COKlBfFp', 1633119725, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:04.889Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('wbgtcUtfDLqx8j3pD29bP5SZMY_wHy3B', 1633119725, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:22:04.835Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('y8YFe_4UABgpp8PHrdYGRzHPg2j9tS5F', 1633119923, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:25:23.429Z\",\"httpOnly\":true,\"path\":\"/\"}}'),
('zgUKLmJ_vZ9fE7jysvyNjLCbhYsAD1IV', 1633119806, '{\"cookie\":{\"originalMaxAge\":600000,\"expires\":\"2021-10-01T20:23:25.648Z\",\"httpOnly\":true,\"path\":\"/\"}}');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipos_documento`
--

CREATE TABLE `tipos_documento` (
  `id_tipos_documento` int(11) NOT NULL,
  `nombre_tipo` varchar(50) COLLATE latin1_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Volcado de datos para la tabla `tipos_documento`
--

INSERT INTO `tipos_documento` (`id_tipos_documento`, `nombre_tipo`) VALUES
(1, 'Documento Nacional de Identidad'),
(2, 'Pasaporte'),
(3, 'Libreta Cívica de Enrolamiento');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_promedios`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_promedios` (
`Promedio` double
,`Materia` varchar(50)
,`Año` int(1)
,`Trimestre` int(11)
,`Alumno` int(11)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `materias_adeudadas`
--
DROP TABLE IF EXISTS `materias_adeudadas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `materias_adeudadas`  AS SELECT avg(`evaluaciones`.`nota`) AS `Promedio`, `materias`.`nombre_mat` AS `Materia`, `materias`.`anio` AS `Año`, `TRIMESTRE_ACTUAL`(`evaluaciones`.`fecha`) AS `Trimestre`, `evaluaciones`.`alumno` AS `Alumno`, year(`evaluaciones`.`fecha`) AS `Año_de_cursada` FROM (`evaluaciones` join `materias` on(`materias`.`id_materia` = `evaluaciones`.`materia`)) WHERE timestampdiff(YEAR,`evaluaciones`.`fecha`,curdate()) >= 1 GROUP BY `evaluaciones`.`materia`, `TRIMESTRE_ACTUAL`(`evaluaciones`.`fecha`), `evaluaciones`.`alumno` HAVING `Promedio` < 6 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_promedios`
--
DROP TABLE IF EXISTS `vista_promedios`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_promedios`  AS SELECT avg(`evaluaciones`.`nota`) AS `Promedio`, `materias`.`nombre_mat` AS `Materia`, `materias`.`anio` AS `Año`, `TRIMESTRE_ACTUAL`(`evaluaciones`.`fecha`) AS `Trimestre`, `evaluaciones`.`alumno` AS `Alumno` FROM (`evaluaciones` join `materias` on(`materias`.`id_materia` = `evaluaciones`.`materia`)) GROUP BY `evaluaciones`.`materia`, `TRIMESTRE_ACTUAL`(`evaluaciones`.`fecha`), `evaluaciones`.`alumno` ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `asistencia`
--
ALTER TABLE `asistencia`
  ADD KEY `asistencia_persona` (`persona`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`categoria_id`);

--
-- Indices de la tabla `comunicaciones`
--
ALTER TABLE `comunicaciones`
  ADD PRIMARY KEY (`id_comunicaciones`),
  ADD KEY `emisor_persona` (`emisor`),
  ADD KEY `receptor_persona` (`receptor`);

--
-- Indices de la tabla `cursos`
--
ALTER TABLE `cursos`
  ADD PRIMARY KEY (`id_curso`),
  ADD KEY `curso_especialidad` (`especialidad`);

--
-- Indices de la tabla `curso_materia`
--
ALTER TABLE `curso_materia`
  ADD KEY `foreign_materia` (`materia`),
  ADD KEY `foreign_curso_materia` (`curso`),
  ADD KEY `especialidad` (`especialidad`),
  ADD KEY `profesor_persona` (`profesor`);

--
-- Indices de la tabla `datos_escolares`
--
ALTER TABLE `datos_escolares`
  ADD PRIMARY KEY (`titulo`);

--
-- Indices de la tabla `especialidades`
--
ALTER TABLE `especialidades`
  ADD PRIMARY KEY (`id_especialidad`);

--
-- Indices de la tabla `evaluaciones`
--
ALTER TABLE `evaluaciones`
  ADD PRIMARY KEY (`id_evaluaciones`),
  ADD KEY `evaluaciones_materia` (`materia`),
  ADD KEY `alumno_persona` (`alumno`);

--
-- Indices de la tabla `materias`
--
ALTER TABLE `materias`
  ADD PRIMARY KEY (`id_materia`);

--
-- Indices de la tabla `personas`
--
ALTER TABLE `personas`
  ADD PRIMARY KEY (`id_persona`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `persona_categoria` (`categoria`),
  ADD KEY `persona_documento` (`tipo_documento`),
  ADD KEY `persona_sesion` (`ultima_sesion`);

--
-- Indices de la tabla `persona_curso`
--
ALTER TABLE `persona_curso`
  ADD KEY `foreign_curso` (`curso`),
  ADD KEY `foreign_persona` (`persona`);

--
-- Indices de la tabla `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`session_id`);

--
-- Indices de la tabla `tipos_documento`
--
ALTER TABLE `tipos_documento`
  ADD PRIMARY KEY (`id_tipos_documento`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `categoria_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `comunicaciones`
--
ALTER TABLE `comunicaciones`
  MODIFY `id_comunicaciones` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `cursos`
--
ALTER TABLE `cursos`
  MODIFY `id_curso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `especialidades`
--
ALTER TABLE `especialidades`
  MODIFY `id_especialidad` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `evaluaciones`
--
ALTER TABLE `evaluaciones`
  MODIFY `id_evaluaciones` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `materias`
--
ALTER TABLE `materias`
  MODIFY `id_materia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `personas`
--
ALTER TABLE `personas`
  MODIFY `id_persona` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `tipos_documento`
--
ALTER TABLE `tipos_documento`
  MODIFY `id_tipos_documento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `asistencia`
--
ALTER TABLE `asistencia`
  ADD CONSTRAINT `asistencia_persona` FOREIGN KEY (`persona`) REFERENCES `personas` (`id_persona`);

--
-- Filtros para la tabla `comunicaciones`
--
ALTER TABLE `comunicaciones`
  ADD CONSTRAINT `emisor_persona` FOREIGN KEY (`emisor`) REFERENCES `personas` (`id_persona`),
  ADD CONSTRAINT `receptor_persona` FOREIGN KEY (`receptor`) REFERENCES `personas` (`id_persona`);

--
-- Filtros para la tabla `cursos`
--
ALTER TABLE `cursos`
  ADD CONSTRAINT `curso_especialidad` FOREIGN KEY (`especialidad`) REFERENCES `especialidades` (`id_especialidad`);

--
-- Filtros para la tabla `curso_materia`
--
ALTER TABLE `curso_materia`
  ADD CONSTRAINT `curso_materia_ibfk_1` FOREIGN KEY (`especialidad`) REFERENCES `especialidades` (`id_especialidad`),
  ADD CONSTRAINT `foreign_curso_materia` FOREIGN KEY (`curso`) REFERENCES `cursos` (`id_curso`),
  ADD CONSTRAINT `foreign_materia` FOREIGN KEY (`materia`) REFERENCES `materias` (`id_materia`),
  ADD CONSTRAINT `profesor_persona` FOREIGN KEY (`profesor`) REFERENCES `personas` (`id_persona`);

--
-- Filtros para la tabla `evaluaciones`
--
ALTER TABLE `evaluaciones`
  ADD CONSTRAINT `alumno_persona` FOREIGN KEY (`alumno`) REFERENCES `personas` (`id_persona`),
  ADD CONSTRAINT `evaluaciones_materia` FOREIGN KEY (`materia`) REFERENCES `materias` (`id_materia`);

--
-- Filtros para la tabla `personas`
--
ALTER TABLE `personas`
  ADD CONSTRAINT `persona_categoria` FOREIGN KEY (`categoria`) REFERENCES `categorias` (`categoria_id`),
  ADD CONSTRAINT `persona_documento` FOREIGN KEY (`tipo_documento`) REFERENCES `tipos_documento` (`id_tipos_documento`),
  ADD CONSTRAINT `persona_sesion` FOREIGN KEY (`ultima_sesion`) REFERENCES `sessions` (`session_id`) ON DELETE SET NULL ON UPDATE SET NULL;

--
-- Filtros para la tabla `persona_curso`
--
ALTER TABLE `persona_curso`
  ADD CONSTRAINT `foreign_curso` FOREIGN KEY (`curso`) REFERENCES `cursos` (`id_curso`),
  ADD CONSTRAINT `foreign_persona` FOREIGN KEY (`persona`) REFERENCES `personas` (`id_persona`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
