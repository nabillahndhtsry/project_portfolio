<?php
// detail.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $id = isset($_GET['id']) ? intval($_GET['id']) : 0;
    
    if ($id <= 0) {
        echo json_encode([
            "success" => false,
            "message" => "ID artikel tidak valid"
        ]);
        exit();
    }
    
    // HANYA gunakan kolom yang ada
    $sql = "SELECT 
                id,
                title,
                content,
                image_url,
                user_id,
                created_at,
                updated_at
            FROM articles 
            WHERE id = $id";
    
    $result = $conn->query($sql);
    
    if ($result->num_rows > 0) {
        $article = $result->fetch_assoc();
        echo json_encode([
            "success" => true,
            "data" => $article
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Artikel tidak ditemukan"
        ]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Method not allowed"]);
}

$conn->close();
?>