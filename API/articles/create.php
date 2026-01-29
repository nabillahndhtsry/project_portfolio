<?php
// create.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

// Matikan output error
ini_set('display_errors', 0);
error_reporting(E_ALL);
ini_set('log_errors', 1);

ob_start();

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    require_once '../config/database.php';
    
    $data = null;
    
    // Cek jika multipart/form-data (upload file)
    if (isset($_POST['user_id'])) {
        $data = (object)[
            'user_id' => $_POST['user_id'] ?? 0,
            'title' => $_POST['title'] ?? '',
            'content' => $_POST['content'] ?? '',
            'image_url' => $_POST['image_url'] ?? ''
        ];
    } 
    // Cek jika application/json
    else {
        $input = file_get_contents('php://input');
        $data = json_decode($input);
    }
    
    if (!$data) {
        throw new Exception("No data received");
    }
    
    // Validasi
    $title = trim($data->title ?? '');
    if (empty($title)) {
        throw new Exception("Judul artikel harus diisi");
    }
    
    $content = trim($data->content ?? '');
    $user_id = intval($data->user_id ?? 0);
    
    // Handle file upload
    $image_path = $data->image_url ?? '';
    
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
    
    // **Gunakan hanya kolom yang ada di tabel: title, content, image_url**
    $sql = "INSERT INTO articles (
                title, content, image_url, user_id, created_at
            ) VALUES (?, ?, ?, ?, NOW())";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $stmt->bind_param(
        "sssi", 
        $title,      // title
        $content,    // content  
        $image_path, // image_url
        $user_id     // user_id
    );
    
    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }
    
    $article_id = $stmt->insert_id;
    $stmt->close();
    
    ob_end_clean();
    
    echo json_encode([
        "success" => true,
        "message" => "Artikel berhasil dibuat",
        "article_id" => $article_id,
        "data" => [
            "id" => $article_id,
            "title" => $title,
            "content" => $content,
            "image_url" => $image_path,
            "user_id" => $user_id,
            "created_at" => date('Y-m-d H:i:s')
        ]
    ]);
    
} catch (Exception $e) {
    ob_end_clean();
    
    http_response_code(500);
    echo json_encode([
        "success" => false, 
        "message" => $e->getMessage()
    ]);
}

exit();
?>