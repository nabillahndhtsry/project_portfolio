<?php

// Mengizinkan permintaan dari origin manapun. Untuk development ini tidak masalah.
// Untuk production, ganti '*' dengan domain web app Anda, contoh: 'https://app.domainanda.com'
header("Access-Control-Allow-Origin: *");

// Mengizinkan header yang dibutuhkan, termasuk Content-Type dan Authorization untuk token.
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");

// Mengizinkan metode HTTP yang akan digunakan.
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

// Browser mengirim request 'preflight' dengan method OPTIONS untuk memastikan request aman.
// Jika request-nya adalah OPTIONS, kita cukup kirim response 200 OK dan berhenti.
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// --- Letakkan sisa kode PHP Anda di bawah ini ---
// Contoh: include 'koneksi.php'; ... dan seterusnya

require_once 'config/database.php';

$data = json_decode(file_get_contents("php://input"));

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = $conn->real_escape_string($data->username ?? '');
    $password = $data->password ?? '';

    $sql = "SELECT * FROM users WHERE username = '$username'";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        $users = $result->fetch_assoc();
        
        // Verifikasi password (password contoh: 123)
        if (password_verify($password, $users['password'])) {
            
            // BUAT TOKEN - TAMBAHKAN INI
            // Token sederhana: gabungkan user id, username, dan timestamp
            $tokenData = $users['id'] . $users['username'] . time();
            $token = base64_encode($tokenData);
            
            // Simpan token ke database (opsional, untuk validasi nanti)
            // $updateToken = "UPDATE users SET token = '$token' WHERE id = " . $users['id'];
            // $conn->query($updateToken);
            
            echo json_encode([
                "success" => true,
                "message" => "Login berhasil",
                "token" => $token, // TAMBAHKAN TOKEN DI SINI
                "user" => [
                    "id" => $users['id'],
                    "username" => $users['username'],
                    "full_name" => $users['full_name'],
                    "email" => $users['email'],
                    "bio" => $users['bio'],
                    
                ]
            ]);
        } else {
            echo json_encode([
                "success" => false,
                "message" => "Password salah"
            ]);
        }
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Username tidak ditemukan"
        ]);
    }
} else {
    echo json_encode(["message" => "Method not allowed"]);
}

$conn->close();
?>