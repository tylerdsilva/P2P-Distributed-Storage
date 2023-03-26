from flask import Flask, render_template, request, session, redirect
import json 
import os 
from flask_cors import CORS 




app = Flask(__name__)
CORS(app)

app.secret_key = 'asdoakfjnadlsfma'



@app.route('/is_alive')
def isAlive():
    return True

@app.route('/error')
def error():
    message = 'Hi this is a place holder.'
    return render_template('upload-error.html', message = message)


@app.route('/success')
def success():
    return render_template('success.html')



if __name__ == '__main__':
    app.run(port=2000, debug = True)