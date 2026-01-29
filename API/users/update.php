<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, PUT");
header("Access-Control-Allow-Headers: Content-Type");

require_once '../config/database.php';

// Fungsi untuk validasi input
function validateInput($data) {
    $errors = [];
    
    if (isset($data['email']) && !empty($data['email'])) {
        if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            $errors[] = "Email tidak valid";
        }
    }
    
    if (isset($data['full_name']) && empty(trim($data['full_name']))) {
        $errors[] = "Nama lengkap tidak boleh kosong";
    }
    
    return $errors;
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' || $_SERVER['REQUEST_METHOD'] == 'PUT') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Debug log
    error_log("Update data received: " . print_r($data, true));
    
    // Validasi input
    $validationErrors = validateInput($data);
    if (!empty($validationErrors)) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Validasi gagal",
            "errors" => $validationErrors
        ]);
        exit();
    }
    
    // Dapatkan user_id (untuk testing gunakan 1, nanti bisa dari session/token)
    $user_id = isset($data['user_id']) ? intval($data['user_id']) : 1;
    
    // Siapkan field yang akan diupdate
    $updates = [];
    $params = [];
    
    if (isset($data['full_name']) && !empty(trim($data['full_name']))) {
        $full_name = $conn->real_escape_string(trim($data['full_name']));
        $updates[] = "full_name = ?";
        $params[] = $full_name;
    }
    
    if (isset($data['email']) && !empty(trim($data['email']))) {
        $email = $conn->real_escape_string(trim($data['email']));
        
        // Cek apakah email sudah digunakan user lain
        $check_stmt = $conn->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
        $check_stmt->bind_param("si", $email, $user_id);
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();
        
        if ($check_result->num_rows > 0) {
            http_response_code(409);
            echo json_encode([
                "success" => false,
                "message" => "Email sudah digunakan"
            ]);
            exit();
        }
        
        $updates[] = "email = ?";
        $params[] = $email;
        $check_stmt->close();
    }
    
    if (isset($data['bio'])) {
        $bio = $conn->real_escape_string(trim($data['bio']));
        $updates[] = "bio = ?";
        $params[] = $bio;
    }
    
    if (isset($data['photo_url'])) {
        $photo_url = $conn->real_escape_string(trim($data['photo_url']));
        $updates[] = "photo_url = ?";
        $params[] = $photo_url;
    }
    
    // Jika ingin update password
    if (isset($data['new_password']) && !empty(trim($data['new_password']))) {
        $new_password_hash = password_hash($data['new_password'], PASSWORD_DEFAULT);
        $updates[] = "password = ?";
        $params[] = $new_password_hash;
    }
    
    if (empty($updates)) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Tidak ada data yang diupdate"
        ]);
        exit();
    }
    
    // Update database dengan prepared statement
    $update_sql = "UPDATE users SET " . implode(", ", $updates) . " WHERE id = ?";
    $params[] = $user_id; // Tambah user_id ke parameter
    
    $stmt = $conn->prepare($update_sql);
    
    // Buat type string untuk bind_param
    $types = str_repeat("s", count($params) - 1) . "i"; // semua string kecuali terakhir integer
    
    // Bind parameter
    $stmt->bind_param($types, ...$params);
    
    if ($stmt->execute()) {
        // Ambil data terbaru
        $select_sql = "SELECT id, username, full_name, email, photo_url, bio, created_at 
                      FROM users WHERE id = ?";
        $select_stmt = $conn->prepare($select_sql);
        $select_stmt->bind_param("i", $user_id);
        $select_stmt->execute();
        $result = $select_stmt->get_result();
        $updated_user = $result->fetch_assoc();
        
        echo json_encode([
            "success" => true,
            "message" => "Profile berhasil diupdate",
            "data" => $updated_user
        ]);
        
        $select_stmt->close();
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Gagal mengupdate profile: " . $stmt->error
        ]);
    }
    
    $stmt->close();
} else {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method not allowed"]);
}

$conn->close();
?>