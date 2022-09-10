-- phpMyAdmin SQL Dump
-- version 4.9.5deb2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Erstellungszeit: 09. Sep 2022 um 13:34
-- Server-Version: 8.0.30-0ubuntu0.20.04.2
-- PHP-Version: 7.4.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Datenbank: `chatbot`
--

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `aliases`
--

CREATE TABLE `aliases` (
  `id` int UNSIGNED NOT NULL,
  `alias` varchar(32) NOT NULL DEFAULT '',
  `client_id` int UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `clients`
--

CREATE TABLE `clients` (
  `id` int UNSIGNED NOT NULL,
  `ip` varchar(16) NOT NULL DEFAULT '',
  `connections` int UNSIGNED NOT NULL DEFAULT '0',
  `guid` varchar(36) NOT NULL DEFAULT '',
  `name` varchar(32) NOT NULL DEFAULT '',
  `level` int UNSIGNED DEFAULT '0',
  `last_connection` varchar(25) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `groups`
--

CREATE TABLE `groups` (
  `id` int UNSIGNED NOT NULL,
  `name` varchar(32) NOT NULL DEFAULT '',
  `keyword` varchar(32) NOT NULL DEFAULT '',
  `level` int UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3;

--
-- Daten für Tabelle `groups`
--

INSERT INTO `groups` (`id`, `name`, `keyword`, `level`) VALUES
(128, 'Super Admin', 'superadmin', 100),
(64, 'Senior Admin', 'senioradmin', 80),
(32, 'Full Admin', 'fulladmin', 60),
(16, 'Admin', 'admin', 40),
(8, 'Moderator', 'mod', 20),
(2, 'Regular', 'reg', 2),
(1, 'User', 'user', 1),
(0, 'Guest', 'guest', 0);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `ipaliases`
--

CREATE TABLE `ipaliases` (
  `id` int UNSIGNED NOT NULL,
  `ip` varchar(16) NOT NULL,
  `client_id` int UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `penalties`
--

CREATE TABLE `penalties` (
  `id` int UNSIGNED NOT NULL,
  `type` enum('Ban','IPBan','TempBan','Kick','Warning') CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT 'Ban',
  `client_id` int UNSIGNED NOT NULL DEFAULT '0',
  `admin_id` int UNSIGNED NOT NULL DEFAULT '0',
  `duration` int UNSIGNED NOT NULL DEFAULT '0',
  `active` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `keyword` varchar(16) NOT NULL DEFAULT '',
  `reason` varchar(255) NOT NULL DEFAULT '',
  `ip` varchar(16) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `time_add` int UNSIGNED NOT NULL DEFAULT '0',
  `time_edit` int UNSIGNED NOT NULL DEFAULT '0',
  `time_expire` int NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3;

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `aliases`
--
ALTER TABLE `aliases`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `alias` (`alias`,`client_id`),
  ADD KEY `client_id` (`client_id`);

--
-- Indizes für die Tabelle `clients`
--
ALTER TABLE `clients`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `guid` (`guid`),
  ADD KEY `name` (`name`);

--
-- Indizes für die Tabelle `groups`
--
ALTER TABLE `groups`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `keyword` (`keyword`),
  ADD KEY `level` (`level`);

--
-- Indizes für die Tabelle `ipaliases`
--
ALTER TABLE `ipaliases`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ipalias` (`ip`,`client_id`),
  ADD KEY `client_id` (`client_id`);

--
-- Indizes für die Tabelle `penalties`
--
ALTER TABLE `penalties`
  ADD PRIMARY KEY (`id`),
  ADD KEY `keyword` (`keyword`),
  ADD KEY `type` (`type`),
  ADD KEY `time_expire` (`time_expire`),
  ADD KEY `time_add` (`time_add`),
  ADD KEY `admin_id` (`admin_id`),
  ADD KEY `inactive` (`active`),
  ADD KEY `client_id` (`client_id`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `aliases`
--
ALTER TABLE `aliases`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `clients`
--
ALTER TABLE `clients`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `ipaliases`
--
ALTER TABLE `ipaliases`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `penalties`
--
ALTER TABLE `penalties`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
