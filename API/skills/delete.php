<?php
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id = $conn->real_escape_string($data->id ?? 0);

    $sql = "DELETE FROM skills WHERE id = $id";

    if ($conn->query($sql) === TRUE) {
        if ($conn->affected_rows > 0) {
            echo json_encode([
                "success" => true,
                "message" => "Skill berhasil dihapus"
            ]);
        } else {
            echo json_encode([
                "success" => false,
                "message" => "Skill tidak ditemukan"
            ]);
        }
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Error: " . $conn->error
        ]);
    }
}

$conn->close();
?>