<?php
// list.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

// HANYA gunakan kolom yang ada di tabel
$sql = "SELECT 
            id,
            title,
            content,
            image_url,
            user_id,
            created_at,
            updated_at
        FROM articles 
        ORDER BY created_at DESC";

$result = $conn->query($sql);

$articles = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $articles[] = [
            'id' => $row['id'],
            'title' => $row['title'] ?? '',
            'content' => $row['content'] ?? '',
            'image_url' => $row['image_url'] ?? '',
            'user_id' => $row['user_id'] ?? 0,
            'created_at' => $row['created_at'] ?? '',
            'updated_at' => $row['updated_at'] ?? ''
        ];
    }
}

echo json_encode([
    "success" => true,
    "data" => $articles
]);

$conn->close();
?>