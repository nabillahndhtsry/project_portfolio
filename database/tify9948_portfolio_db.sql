-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Waktu pembuatan: 29 Jan 2026 pada 18.35
-- Versi server: 10.11.14-MariaDB-cll-lve
-- Versi PHP: 8.4.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tify9948_portfolio_db`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `articles`
--

CREATE TABLE `articles` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `content` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `articles`
--

INSERT INTO `articles` (`id`, `user_id`, `title`, `content`, `image_url`, `created_at`, `updated_at`) VALUES
(3, 1, 'Belajar REST API', 'Tutorial membuat REST API dengan PHP dan MySQL', 'https://picsum.photos/200/301', '2026-01-21 02:43:11', '2026-01-21 02:43:11'),
(4, 1, 'Belajar REST API', 'Tutorial membuat REST API dengan PHP dan MySQL', 'https://picsum.photos/200/301', '2026-01-21 10:07:45', '2026-01-21 10:07:45'),
(5, 1, 'project', 'mem buat dart', 'uploads/articles/1768990121_article_1768990119440.jpg', '2026-01-21 10:08:41', '2026-01-21 10:10:35'),
(8, 1, 'figma', 'membuat tampilan ui', 'uploads/articles/1769683861_article_1769683854057.jpg', '2026-01-29 10:51:01', '2026-01-29 10:51:01'),
(9, 1, 'Project Framework', 'Membuat', 'uploads/articles/1769684316_article_1769684309940.jpg', '2026-01-29 10:58:36', '2026-01-29 10:58:36');

-- --------------------------------------------------------

--
-- Struktur dari tabel `skills`
--

CREATE TABLE `skills` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `skill_name` varchar(100) DEFAULT NULL,
  `level` varchar(50) DEFAULT NULL,
  `icon_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `skills`
--

INSERT INTO `skills` (`id`, `user_id`, `skill_name`, `level`, `icon_url`) VALUES
(3, 1, 'figma', '75', NULL),
(4, 1, 'dart', '40', NULL);

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `full_name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `bio` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `full_name`, `email`, `photo_url`, `bio`, `created_at`) VALUES
(1, 'admin', '$2y$10$5Zt5VSDvt83Q5ub50Qto5uXedlv8SQJD5OPue67KniTkeUsHZUROq', 'Nabillah Indah Tsuraya', 'nabillahtrsy412@gmail.com', 'https://i.pinimg.com/736x/f9/ba/58/f9ba58fa18863e3a5bc4fbadd9d5de00.jpg', '2023230019', '2026-01-11 05:01:45'),
(2, 'tsuraya', '$2y$10$4LQOqOdfD2en55LmND0cue5hNVaAh3JxYv6AsklmpGJIe36iE58b.', 'tsuraya', 'tsuraya@gmail.com', 'https://i.pinimg.com/736x/ac/5f/b7/ac5fb736c6cb5244828de28e61dd7cd5.jpg', 'halo', '2026-01-28 05:54:09'),
(3, 'testuser', '$2y$10$WTDz3lKhETNky1og09rQ0uDA7hN3nscHIjXrbFXnRS8HiQHgizxpy', 'Test User', 'test@email.com', 'https://cdn-icons-png.flaticon.com/512/847/847969.png', NULL, '2026-01-29 09:48:37'),
(4, 'indah', '$2y$10$OfWzH9RtyGRDAHaLbjdDEOsBVPKpkal5W2Z/SWTXY6Lrp54cjzCQO', 'indah', 'indah@gmail.com', 'https://cdn-icons-png.flaticon.com/512/847/847969.png', NULL, '2026-01-29 10:07:16');

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `articles`
--
ALTER TABLE `articles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indeks untuk tabel `skills`
--
ALTER TABLE `skills`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indeks untuk tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `articles`
--
ALTER TABLE `articles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT untuk tabel `skills`
--
ALTER TABLE `skills`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `articles`
--
ALTER TABLE `articles`
  ADD CONSTRAINT `articles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Ketidakleluasaan untuk tabel `skills`
--
ALTER TABLE `skills`
  ADD CONSTRAINT `skills_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
