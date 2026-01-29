<?php
// update.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';

ini_set('display_errors', 0);
error_reporting(E_ALL);

try {
    $data = null;
    
    // Jika multipart/form-data
    if (isset($_POST['id'])) {
        $data = [
            'id' => $_POST['id'] ?? 0,
            'title' => $_POST['title'] ?? '',
            'content' => $_POST['content'] ?? '',
            'image_url' => $_POST['image_url'] ?? ''
        ];
    } else {
        $input = file_get_contents("php://input");
        $data = json_decode($input, true);
    }
    
    if (empty($data['id']) || empty($data['title'])) {
        echo json_encode([
            "success" => false,
            "message" => "ID dan title harus diisi"
        ]);
        exit();
    }
    
    // Handle file upload jika ada
    $image_path = $data['image_url'] ?? '';
    if (isset($_FILES['image']) && $_FILES['image']['error'] == UPLOAD_ERR_OK) {
        $upload_dir = '../uploads/articles/';
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }
        
        $file_name = time() . '_' . basename($_FILES['image']['name']);
        $file_path = $upload_dir . $file_name;
        
        if (move_uploaded_file($_FILES['image']['tmp_name'], $file_path)) {
            $image_path = 'uploads/articles/' . $file_name;
        }
    }
    
    // Update database - HANYA gunakan kolom yang ada
    $id = intval($data['id']);
    $title = $conn->real_escape_string($data['title']);
    $content = $conn->real_escape_string($data['content']);
    
    $sql = "UPDATE articles SET 
            title = '$title',
            content = '$content',
            image_url = '$image_path',
            updated_at = NOW()
            WHERE id = $id";
    
    if ($conn->query($sql)) {
        echo json_encode([
            "success" => true,
            "message" => "Artikel berhasil diperbarui"
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Gagal memperbarui artikel: " . $conn->error
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => "Error: " . $e->getMessage()
    ]);
}

$conn->close();
?>