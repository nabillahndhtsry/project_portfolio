<?php
require_once '../config/database.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (empty($data['user_id']) || empty($data['skill_name'])) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "User ID dan nama skill harus diisi"
        ]);
        exit();
    }
    
    $user_id = $conn->real_escape_string($data['user_id']);
    $skill_name = $conn->real_escape_string($data['skill_name']);
    $level = isset($data['level']) ? intval($data['level']) : 0;
    
    // Validasi level
    if ($level < 0) $level = 0;
    if ($level > 100) $level = 100;
    
    $sql = "INSERT INTO skills (user_id, skill_name, level) 
            VALUES ('$user_id', '$skill_name', '$level')";
    
    if ($conn->query($sql) === TRUE) {
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "message" => "Skill berhasil ditambahkan",
            "data" => [
                "id" => $conn->insert_id,
                "user_id" => $user_id,
                "skill_name" => $skill_name,
                "level" => $level
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Gagal menambahkan skill: " . $conn->error
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method not allowed"]);
}

$conn->close();
?>