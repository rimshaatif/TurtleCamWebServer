from flask import Flask, render_template, request, send_file

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload_file():
    # file = request.files['file']
    # file.save(f'/path/to/save/{file.filename}')
    # return "File uploaded successfully"
    return render_template("upload.html")

@app.route('/download', methods=['GET'])
def download_file():
    
    #return send_file(f'/path/to/files/{filename}', as_attachment=True)
    return render_template("download.html")
    


@app.route('/')
def home():
   return render_template('homepage.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
