<?php
require_once '../config/database.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (empty($data['id']) || empty($data['skill_name'])) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "ID dan nama skill harus diisi"
        ]);
        exit();
    }
    
    $id = $conn->real_escape_string($data['id']);
    $skill_name = $conn->real_escape_string($data['skill_name']);
    $level = isset($data['level']) ? intval($data['level']) : 0;
    
    // Validasi level
    if ($level < 0) $level = 0;
    if ($level > 100) $level = 100;
    
    $sql = "UPDATE skills SET 
            skill_name = '$skill_name', 
            level = '$level'
            WHERE id = $id";
    
    if ($conn->query($sql) === TRUE) {
        if ($conn->affected_rows > 0) {
            echo json_encode([
                "success" => true,
                "message" => "Skill berhasil diperbarui"
            ]);
        } else {
            http_response_code(404);
            echo json_encode([
                "success" => false,
                "message" => "Skill tidak ditemukan"
            ]);
        }
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Gagal memperbarui skill: " . $conn->error
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method not allowed"]);
}

$conn->close();
?>