<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once '../config/database.php';

// Fungsi untuk mendapatkan user_id dari parameter
function getUserId() {
    // Cara 1: Dari parameter GET
    if (isset($_GET['user_id'])) {
        return intval($_GET['user_id']);
    }
    
    // Cara 2: Dari body POST
    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        $data = json_decode(file_get_contents("php://input"), true);
        if (isset($data['user_id'])) {
            return intval($data['user_id']);
        }
    }
    
    // Default ke user_id 1 untuk testing
    return 1;
}

if ($_SERVER['REQUEST_METHOD'] == 'GET' || $_SERVER['REQUEST_METHOD'] == 'POST') {
    $user_id = getUserId();
    
    // Debug log
    error_log("Fetching profile for user_id: $user_id");
    
    $sql = "SELECT id, username, full_name, email, photo_url, bio, created_at 
            FROM users WHERE id = $user_id";
    
    $result = $conn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        $user = $result->fetch_assoc();
        
        // Pastikan semua field ada
        $user['id'] = intval($user['id']);
        $user['username'] = $user['username'] ?? '';
        $user['full_name'] = $user['full_name'] ?? '';
        $user['email'] = $user['email'] ?? '';
        $user['bio'] = $user['bio'] ?? '';
        $user['photo_url'] = $user['photo_url'] ?? '';
        $user['created_at'] = $user['created_at'] ?? '';
        
        echo json_encode([
            "success" => true,
            "message" => "Profile berhasil diambil",
            "data" => $user
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "User tidak ditemukan",
            "user_id" => $user_id
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method not allowed"]);
}

$conn->close();
?>