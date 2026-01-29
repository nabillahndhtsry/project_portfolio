<?php
// File: skills/list.php (UNTUK SKILLS)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

try {
    // **PERBAIKAN: Query untuk skills, bukan articles**
    $sql = "SELECT * FROM skills ORDER BY id DESC";
    
    $result = $conn->query($sql);
    
    $skills = [];
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $skills[] = [
                'id' => $row['id'],
                'skill_name' => $row['skill_name'],
                'level' => $row['level'],
                'user_id' => $row['user_id'],
                'icon_url' => $row['icon_url'] ?? null
            ];
        }
    }
    
    echo json_encode([
        "success" => true,
        "data" => $skills,
        "total" => count($skills)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Error: " . $e->getMessage()
    ]);
}

$conn->close();
?>