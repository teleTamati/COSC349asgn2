#!/bin/bash
echo "🔌 Setting up API VM..."

apt-get update
apt-get install -y apache2 php libapache2-mod-php php-mysql

rm -f /var/www/html/index.html

# Embed your api.php directly  
cat <<'EOF' >/var/www/html/api.php
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

$db_host = '${database_server_private_ip}';
$db_name = 'tasktracker';
$db_user = 'apiuser';
$db_passwd = 'insecure_api_pw';

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_passwd);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $method = $_SERVER['REQUEST_METHOD'];
    $input = json_decode(file_get_contents('php://input'), true);
    
    switch ($method) {
        case 'GET':
            // Get all tasks
            $query = $pdo->query("SELECT * FROM tasks ORDER BY due_date ASC");
            $tasks = $query->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'tasks' => $tasks]);
            break;
            
        case 'POST':
            // Add new task
            if (!isset($input['title'])) {
                echo json_encode(['success' => false, 'message' => 'Title required']);
                exit;
            }
            
            $stmt = $pdo->prepare("INSERT INTO tasks (title, description, priority, due_date) VALUES (?, ?, ?, ?)");
            $stmt->execute([
                $input['title'],
                $input['description'] ?? '',
                $input['priority'] ?? 'medium',
                $input['due_date'] ?? null
            ]);
            
            echo json_encode(['success' => true, 'message' => 'Task created', 'id' => $pdo->lastInsertId()]);
            break;
            
        case 'PUT':
            // Toggle task completion
            if (!isset($input['id'])) {
                echo json_encode(['success' => false, 'message' => 'Task ID required']);
                exit;
            }
            
            $stmt = $pdo->prepare("UPDATE tasks SET completed = NOT completed WHERE id = ?");
            $stmt->execute([$input['id']]);
            
            echo json_encode(['success' => true, 'message' => 'Task updated']);
            break;
            
        case 'DELETE':
            // Delete task
            if (!isset($input['id'])) {
                echo json_encode(['success' => false, 'message' => 'Task ID required']);
                exit;
            }
            
            $stmt = $pdo->prepare("DELETE FROM tasks WHERE id = ?");
            $stmt->execute([$input['id']]);
            
            echo json_encode(['success' => true, 'message' => 'Task deleted']);
            break;
            
        default:
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    }
    
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
EOF

chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

service apache2 restart

echo "✅ API VM ready"