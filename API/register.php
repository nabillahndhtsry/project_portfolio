<?php
// Mengizinkan permintaan dari origin manapun
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config/database.php';

// Baca data JSON dari input
$data = json_decode(file_get_contents("php://input"));

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Validasi data
    if (empty($data->full_name) || empty($data->username) || empty($data->email) || empty($data->password)) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Semua field wajib diisi (full_name, username, email, password)"
        ]);
        exit();
    }
    
    // Escape data
    $full_name = $conn->real_escape_string($data->full_name ?? '');
    $username = $conn->real_escape_string($data->username ?? '');
    $email = $conn->real_escape_string($data->email ?? '');
    $password = $data->password ?? '';
    
    // 1. Cek apakah username sudah ada
    $checkUsername = $conn->query("SELECT id FROM users WHERE username = '$username'");
    if ($checkUsername->num_rows > 0) {
        http_response_code(409);
        echo json_encode([
            "success" => false,
            "message" => "Username sudah digunakan"
        ]);
        exit();
    }
    
    // 2. Cek apakah email sudah ada
    $checkEmail = $conn->query("SELECT id FROM users WHERE email = '$email'");
    if ($checkEmail->num_rows > 0) {
        http_response_code(409);
        echo json_encode([
            "success" => false,
            "message" => "Email sudah terdaftar"
        ]);
        exit();
    }
    
    // 3. Hash password
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);
    
    // 4. Foto default
    $default_photo_url = 'https://cdn-icons-png.flaticon.com/512/847/847969.png';
    
    // 5. Waktu sekarang
    $created_at = date('Y-m-d H:i:s');
    
    // 6. Buat query insert
    $sql = "INSERT INTO users (full_name, username, email, password, photo_url, created_at) 
            VALUES ('$full_name', '$username', '$email', '$hashed_password', '$default_photo_url', '$created_at')";
    
    if ($conn->query($sql) === TRUE) {
        // Ambil ID user yang baru dibuat
        $new_user_id = $conn->insert_id;
        
        // Buat token (sama seperti login)
        $tokenData = $new_user_id . $username . time();
        $token = base64_encode($tokenData);
        
        // Response sukses
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "message" => "Registrasi berhasil",
            "token" => $token,
            "user" => [
                "id" => $new_user_id,
                "full_name" => $full_name,
                "username" => $username,
                "email" => $email,
                "photo_url" => $default_photo_url,
                "created_at" => $created_at
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Gagal membuat akun: " . $conn->error
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method tidak diizinkan. Gunakan POST."
    ]);
}

$conn->close();
?>