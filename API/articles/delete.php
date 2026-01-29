<?php
// delete.php - tetap sama
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"), true);

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (empty($data['id'])) {
        echo json_encode([
            "success" => false,
            "message" => "ID artikel harus diisi"
        ]);
        exit();
    }
    
    $id = intval($data['id']);
    
    $sql = "DELETE FROM articles WHERE id = $id";
    
    if ($conn->query($sql)) {
        echo json_encode([
            "success" => true,
            "message" => "Artikel berhasil dihapus"
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Gagal menghapus artikel: " . $conn->error
        ]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Method not allowed"]);
}

$conn->close();
?>