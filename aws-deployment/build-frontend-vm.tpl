#!/bin/bash
echo "Setting up Frontend VM..."

apt-get update
apt-get install -y apache2

rm -f /var/www/html/index.html

# Embed your index.html directly
cat <<'EOF' >/var/www/html/index.html

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Tracker - 3 VM Architecture</title>
    <style>
        body { 
            font-family: 'Segoe UI', Arial, sans-serif; 
            margin: 0; 
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { 
            max-width: 1000px; 
            margin: 0 auto; 
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #333; 
            text-align: center; 
            margin-bottom: 30px;
            font-size: 2.5em;
        }
        
        .add-task {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }
        .form-row {
            display: grid;
            grid-template-columns: 2fr 3fr 1fr 1fr auto;
            gap: 15px;
            align-items: center;
        }
        .form-row input, .form-row select {
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        
        button {
            background: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.3s;
        }
        button:hover { background: #0056b3; }
        .btn-done { 
            background: #28a745; 
            padding: 5px 15px;
            font-size: 12px;
        }
        .btn-done:hover { background: #218838; }
        
        .status { 
            padding: 10px; 
            margin: 10px 0; 
            border-radius: 4px;
            text-align: center;
            font-weight: 500;
        }
        .loading { background-color: #e3f2fd; color: #1976d2; }
        .error { background-color: #ffebee; color: #c62828; }
        .success { background-color: #e8f5e8; color: #2e7d32; }
        
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin-top: 20px;
        }
        th, td { 
            padding: 12px; 
            text-align: left; 
            border-bottom: 1px solid #ddd; 
        }
        th { 
            background-color: #f8f9fa; 
            font-weight: 600;
            color: #555;
        }
        tr:hover { background-color: #f5f5f5; }
        
        .priority-high { color: #d32f2f; font-weight: bold; }
        .priority-medium { color: #f57c00; font-weight: 500; }
        .priority-low { color: #388e3c; }
        
        /* NEW: Due date styling */
        .overdue { 
            color: #d32f2f; 
            font-weight: bold;
            background-color: #ffebee;
            padding: 2px 6px;
            border-radius: 3px;
        }
        
        .due-soon { 
            color: #f57c00; 
            font-weight: 500;
            background-color: #fff3e0;
            padding: 2px 6px;
            border-radius: 3px;
        }
        
        .due-normal { 
            color: #388e3c; 
        }
        
        .architecture {
            margin-top: 30px;
            padding: 20px;
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border-radius: 8px;
            font-size: 14px;
        }

        .no-tasks {
            text-align: center;
            padding: 40px 20px;
            color: #666;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Tele's Free Task Tracker</h1>
        <div id="status" class="status loading">Connecting to 3-VM architecture...</div>
        
        <div class="add-task">
            <h3>➕ Add New Task</h3>
            <div class="form-row">
                <input type="text" id="newTitle" placeholder="Task title..." required>
                <input type="text" id="newDescription" placeholder="Description...">
                <input type="date" id="newDueDate" placeholder="Due date...">
                <select id="newPriority">
                    <option value="low">Low Priority</option>
                    <option value="medium" selected>Medium Priority</option>
                    <option value="high">High Priority</option>
                </select>
                <button onclick="addTask()">Add Task</button>
            </div>
        </div>
        
        <div id="tasksContainer">
            <table id="tasksTable" style="display: none;">
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Description</th>
                        <th>Priority</th>
                        <th>Due Date</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody id="tasksBody">
                </tbody>
            </table>
            <div id="noTasks" class="no-tasks" style="display: none;">
                No tasks yet. Add your first task above!
            </div>
        </div>
        
        <div class="architecture">
            <h3>3-VM Microservices Architecture</h3>
            <p><strong>Frontend VM (This VM):</strong> JavaScript SPA - This interface</p>
            <p><strong>API VM (${api_server_ip}):</strong> PHP REST API - Handles business logic</p>
            <p><strong>Database VM (Internal):</strong> MySQL Database - Data persistence</p>
           
        </div>
    </div>

    <script>
        // API Base URL
        const API_URL = 'http://${api_server_ip}/api.php';
        
        // Load and display tasks
        async function loadTasks() {
            try {
                const response = await fetch(API_URL);
                const data = await response.json();
                
                const statusDiv = document.getElementById('status');
                const table = document.getElementById('tasksTable');
                const tbody = document.getElementById('tasksBody');
                const noTasks = document.getElementById('noTasks');
                
                if (data.success) {
                    statusDiv.className = 'status success';
                    statusDiv.textContent = `$${data.tasks.length} tasks recorded`;
                    
                    // Clear previous content
                    tbody.innerHTML = '';
                    
                    if (data.tasks.length > 0) {
                        // Show table, hide no-tasks message
                        table.style.display = 'table';
                        noTasks.style.display = 'none';
                        
                        data.tasks.forEach(task => {
                            const row = tbody.insertRow();
                            const priorityClass = `priority-$${task.priority}`;
                            const dueDateClass = getDueDateClass(task.due_date);
                            
                            row.innerHTML = `
                                <td><strong>$${escapeHtml(task.title)}</strong></td>
                                <td>$${escapeHtml(task.description)}</td>
                                <td class="$${priorityClass}">$${capitalizeFirst(task.priority)}</td>
                                <td class="$${dueDateClass}">$${formatDueDate(task.due_date)}</td>
                                <td>
                                    <button class="btn-done" onclick="markDone($${task.id})">
                                        Done
                                    </button>
                                </td>
                            `;
                        });
                    } else {
                        // Hide table, show no-tasks message
                        table.style.display = 'none';
                        noTasks.style.display = 'block';
                    }
                } else {
                    statusDiv.className = 'status error';
                    statusDiv.textContent = `API Error: $${data.message}`;
                }
            } catch (error) {
                const statusDiv = document.getElementById('status');
                statusDiv.className = 'status error';
                statusDiv.textContent = `Connection Failed: $${error.message}`;
                console.error('Load tasks error:', error);
            }
        }
        
        // Add new task
        async function addTask() {
            const title = document.getElementById('newTitle').value.trim();
            if (!title) {
                alert('Please enter a task title');
                return;
            }
            
            const taskData = {
                title: title,
                description: document.getElementById('newDescription').value.trim(),
                priority: document.getElementById('newPriority').value,
                due_date: document.getElementById('newDueDate').value || null
            };
            
            try {
                const response = await fetch(API_URL, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(taskData)
                });
                
                const result = await response.json();
                if (result.success) {
                    // Clear form
                    document.getElementById('newTitle').value = '';
                    document.getElementById('newDescription').value = '';
                    document.getElementById('newPriority').value = 'medium';
                    document.getElementById('newDueDate').value = '';
                    
                    // Reload tasks
                    loadTasks();
                } else {
                    alert('Error: ' + result.message);
                }
            } catch (error) {
                alert('Connection error: ' + error.message);
                console.error('Add task error:', error);
            }
        }
        
        // Mark task as done (delete it)
        async function markDone(id) {
            try {
                const response = await fetch(API_URL, {
                    method: 'DELETE',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ id: id })
                });
                
                const result = await response.json();
                if (result.success) {
                    loadTasks();
                } else {
                    alert('Error: ' + result.message);
                }
            } catch (error) {
                alert('Connection error: ' + error.message);
                console.error('Mark done error:', error);
            }
        }
        
        // NEW: Due date helper functions
        function formatDueDate(dueDate) {
            if (!dueDate) return 'No date set';
            const date = new Date(dueDate);
            return date.toLocaleDateString();
        }
        
        function getDueDateClass(dueDate) {
            if (!dueDate) return '';
            
            const today = new Date();
            today.setHours(0, 0, 0, 0); // Start of today
            const due = new Date(dueDate);
            due.setHours(0, 0, 0, 0); // Start of due date
            
            const diffTime = due - today;
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            
            if (diffDays < 0) return 'overdue';
            if (diffDays <= 1) return 'due-soon';
            return 'due-normal';
        }
        
        // Utility functions
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        function capitalizeFirst(str) {
            return str.charAt(0).toUpperCase() + str.slice(1);
        }
        
        // Initialize when page loads
        document.addEventListener('DOMContentLoaded', function() {
            loadTasks();
        });
    </script>
</body>
</html>
EOF

chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

service apache2 restart

echo "Frontend VM ready"
