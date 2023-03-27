from flask import Flask, flash, render_template, request, session, redirect, url_for
import json 
import os 
from werkzeug.utils import secure_filename
from flask_cors import CORS 

UPLOAD_FOLDER = 'temp'


app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
CORS(app)

app.secret_key = 'asdoakfjnadlsfma'



@app.route('/is_alive')
def isAlive():
    return True

@app.route('/error')
def error(message):
    return render_template('upload-error.html', message = message)


@app.route('/success')
def success():
    return render_template('success.html')

@app.route('/upload', methods=['GET', 'POST'])
def upload():
    if request.method == 'POST':
        # check if the post request has the file part
        if 'file' not in request.files:
            flash('No file part')
            return error('No file part')
        file = request.files['file']
        # If the user does not select a file, the browser submits an
        # empty file without a filename.
        if file.filename == '':
            flash('No selected file')
            return error('No selected file')
        if file:
            filename = secure_filename(file.filename)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            return success()
    return render_template('upload-webpage.html')



if __name__ == '__main__':
    app.run(port=2000, debug = True)