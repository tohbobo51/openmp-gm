-- ========================================================================
--         VICE SIDE ROLEPLAY - DATABASE SCHEMA (MYSQL / MARIADB)
-- ========================================================================
-- Kompatibel dengan LemeHost, MariaDB 10.x+, dan MySQL 8.x
-- ========================================================================

-- 1. TABEL AKUN UCP (GOOGLE OAUTH 2.0)
CREATE TABLE IF NOT EXISTS `ucp_accounts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `google_id` VARCHAR(64) NOT NULL UNIQUE,
    `google_email` VARCHAR(128) NOT NULL UNIQUE,
    `ucp_name` VARCHAR(32) NOT NULL,
    `registered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_login` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_google_id` (`google_id`),
    INDEX `idx_google_email` (`google_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. TABEL KARAKTER IN-GAME (IC)
CREATE TABLE IF NOT EXISTS `characters` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `ucp_id` INT NOT NULL,
    `character_name` VARCHAR(24) NOT NULL UNIQUE,
    `birthplace` VARCHAR(64) NOT NULL,
    `birthdate` DATE NOT NULL,
    `gender` ENUM('Male', 'Female') NOT NULL DEFAULT 'Male',
    `height` INT NOT NULL DEFAULT 175,
    `weight` INT NOT NULL DEFAULT 70,
    
    -- Status Bawaan Game
    `money` INT NOT NULL DEFAULT 500,
    `bank_money` INT NOT NULL DEFAULT 1000,
    `skin` INT NOT NULL DEFAULT 299,
    `pos_x` FLOAT NOT NULL DEFAULT 1481.0425,
    `pos_y` FLOAT NOT NULL DEFAULT -1750.0450,
    `pos_z` FLOAT NOT NULL DEFAULT 15.4453,
    `pos_a` FLOAT NOT NULL DEFAULT 0.0,
    `interior` INT NOT NULL DEFAULT 0,
    `virtual_world` INT NOT NULL DEFAULT 0,
    
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_characters_ucp` FOREIGN KEY (`ucp_id`) REFERENCES `ucp_accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
