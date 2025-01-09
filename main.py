from flask import Flask, render_template, request, send_file, jsonify
import psutil
import os
import json
import zipfile
import io
import subprocess
app = Flask(__name__)

CONFIG_PATH = os.path.join(os.path.dirname(__file__), 'scripts', 'config.json')

@app.route('/run-command', methods=['POST'])
def run_command():
    # Get the command from the request
    data = request.json
    command = data.get('command')

    if not command:
        return jsonify({'error': 'No command provided'}), 400

    try:
        # Run the command
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        # Construct the response with command results
        response = {
            'output': result.stdout.strip(),  # Command standard output
            'error': result.stderr.strip(),  # Command standard error
            'returncode': result.returncode  # Command return code
        }

        return jsonify(response), 200 if result.returncode == 0 else 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/upload', methods=['GET'])
def upload_file():
    return render_template("upload.html")

@app.route('/download-multiple', methods=['GET'])
def download_multiple():
    directory = request.args.get('directory')
    files = request.args.get('files')
    files = json.loads(files)  # Parse the JSON string into a Python list
    zip_name = request.args.get('zipName', 'files')  # Default to 'files.zip'

    if not os.path.exists(directory):
        return "Directory not found", 404

    # Create a ZIP archive in memory
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        for file_name in files:
            file_path = os.path.join(directory, file_name)
            if os.path.exists(file_path):
                zip_file.write(file_path, file_name)  # Add file to the ZIP archive
    zip_buffer.seek(0)

   # Prepare ZIP file for download
    zip_name_with_ext = f"{zip_name}.zip"
    return send_file(
        zip_buffer,
        mimetype='application/zip',
        as_attachment=True,
        download_name=zip_name_with_ext
    )

@app.route('/download', methods=['GET'])
def download():
    #return send_file(f'/path/to/files/{filename}', as_attachment=True)
    return render_template("download.html")

@app.route('/list-files', methods=['GET'])
def list_files():
    directory = request.args.get('directory')
    if not os.path.exists(directory) or not os.path.isdir(directory):
        return jsonify([]), 404
    
    # Get the full path for each file and filter only files
    files = [file for file in os.listdir(directory) if os.path.isfile(os.path.join(directory, file))]
    return jsonify(files)

@app.route('/save-config', methods=['POST'])
def save_config():
    try:
        config_data = request.get_json()
        print(f"Received config data: {config_data}")
        json_object = json.loads(config_data)
        # Save the configuration to the config.json file
        with open(CONFIG_PATH, 'w') as config_file:
            json.dump(json_object, config_file, indent=4)
        return jsonify({"message": "Configuration saved successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
def get_system_info():
    info = {
        
        "memory": psutil.virtual_memory().percent,
        "disk": psutil.disk_usage('/').percent,
        "uptime": get_uptime()
    }
    return info

def get_uptime():
    # Get system uptime
    return os.popen('uptime -p').read().strip()

@app.route('/')
def home():
    status_info = get_system_info()
    return render_template('homepage.html', status= status_info)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
