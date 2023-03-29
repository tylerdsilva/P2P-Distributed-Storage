from flask import Flask, flash, render_template, request, session, redirect, url_for, jsonify
from pyngrok import ngrok
import json
import os 
from werkzeug.utils import secure_filename
from flask_cors import CORS 
import base64



UPLOAD_FOLDER = 'temp'
FILES_FOLDER = 'files'

app = Flask(__name__)


app.secret_key = 'asdoakfjnadlsfma'

CORS(app)


@app.route('/is_alive')
def isAlive():
    return True

@app.route('/error')
def error():
    message = request.args.get('message', 'Placeholder')
    return render_template('error.html', message = message)


@app.route('/success-upload')
def success():
    return render_template('success-upload.html')

@app.route('/success-download')
def success():
    return render_template('success-download.html')

@app.route('/upload', methods=['GET', 'POST'])
def upload():
    if request.method == 'POST':
        key = request.form['key']
        account = request.form['account']
        file = request.files['file']
   
        filename = secure_filename(file.filename)
        file.save(os.path.join(UPLOAD_FOLDER, filename))
        
        
        return jsonify({'status': True})

    return render_template('upload.html')

@app.route('/download', methods=['GET', 'POST'])
def download():
    if request.method == 'POST':
        hash = request.json.get('hash')
        account = request.json.get('account')

        print(hash,account)


        files = os.listdir(FILES_FOLDER)
        for file in files:
            name = file.split('.')[0]
            if hash == name:
                with open(FILES_FOLDER + '/' + file, 'rb') as f:
                    file_data = f.read()
                
                file_data_b64 = base64.b64encode(file_data).decode('utf-8')
                return jsonify({'status': True, 'filename': file, 'filedata': file_data_b64})
        
        return jsonify({'status': False, 'message': 'File Lost!'})
        
    

    return render_template('download.html')




if __name__ == '__main__':

    authtoken = input("Enter your ngrok authtoken: ")
    ngrok.set_auth_token(authtoken) # Set the authtoken dynamically
    
    http_tunnel = ngrok.connect(6000, options={"bind_tls": True})

    print("Public URL:", http_tunnel.public_url)
   

    app.run(port=6000, debug = False)


   


