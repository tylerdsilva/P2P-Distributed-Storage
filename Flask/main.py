from flask import Flask, flash, render_template, request, session, redirect, url_for, jsonify
from pyngrok import ngrok
import json
import os 
from werkzeug.utils import secure_filename
from flask_cors import CORS 
import base64
from web3 import Web3
import hashlib 
import math

with open("contract.json", "r") as f:
    contractVariables = json.load(f)

# Connect to goerli test network
w3 = Web3(Web3.HTTPProvider(''))


# Load the contract
contract = w3.eth.contract(address=contractVariables['address'], abi=contractVariables['abi'])

peerWallet = None
ip = None

UPLOAD_FOLDER = 'temp'
FILES_FOLDER = 'files'

app = Flask(__name__)


app.secret_key = 'asdoakfjnadlsfma'

CORS(app)

def fileHash(path):
    with open(path, "rb") as f:
    # Read the file in chunks to avoid loading the entire file into memory at once
        chunk_size = 4096
        hash_func = hashlib.sha256()
        while chunk := f.read(chunk_size):
            hash_func.update(chunk)

        # Get the hexadecimal representation of the hash
        hash_hex = hash_func.hexdigest()
        return hash_hex


@app.route('/is_alive')
def isAlive():
    return True

@app.route('/error')
def error():
    message = request.args.get('message', 'Placeholder')
    return render_template('error.html', message = message)


@app.route('/success-upload')
def success_upload():
    hash = request.args.get('hash', 'Placeholder')
    return render_template('success-upload.html', hash = hash)

@app.route('/success-download')
def success_download():
    return render_template('success-download.html')

@app.route('/upload', methods=['GET', 'POST'])
def upload():
    if request.method == 'POST':
        key = int(request.form['key'])
        account = request.form['account']
        file = request.files['file']
   
        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)

        filesize = math.ceil(os.stat(filepath).st_size / (1024 * 1024))

        result = contract.functions.authenticateKey(key, peerWallet, account, filesize).call()
        
        if result[1] != "Key Found.":
            os.remove(filepath)
            return jsonify({'status': False, 'message': result[1]})

        hash = fileHash(filepath)
        newFileName = hash + '.' +filename.split('.')[-1]
        dest = os.path.join(FILES_FOLDER, newFileName)
        os.rename(filepath, dest)


        gas_estimate = contract.functions.storeFile(hash, key, peerWallet, account, filesize).estimate_gas()

        transaction = contract.functions.storeFile(hash, key, peerWallet, account, filesize).build_transaction({
            'from': contractVariables['billingAddress'],
            'gas': gas_estimate+10,
            'gasPrice': w3.to_wei('20', 'gwei'),
            'nonce': w3.eth.get_transaction_count(contractVariables['billingAddress']),
        })


        signed_transaction = w3.eth.account.sign_transaction(transaction, private_key= contractVariables['privateKey'])
        transaction_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
        transaction_receipt = w3.eth.wait_for_transaction_receipt(transaction_hash)

        return jsonify({'status': True, 'hash': hash} )
    
  
    return render_template('upload.html')

@app.route('/download', methods=['GET', 'POST'])
def download():
    if request.method == 'POST':
        hash = request.json.get('hash')

        account = request.json.get('account')

        result = contract.functions.authenticate(hash, account, peerWallet).call()
        print(result)

        if result == "True":
            files = os.listdir(FILES_FOLDER)
            for file in files:
                name = file.split('.')[0]
                if hash == name:
                    with open(FILES_FOLDER + '/' + file, 'rb') as f:
                        file_data = f.read()
                    
                    file_data_b64 = base64.b64encode(file_data).decode('utf-8')
                    return jsonify({'status': True, 'filename': file, 'filedata': file_data_b64})
            
            return jsonify({'status': False, 'message': 'File Lost.'})
        
        else:
            return jsonify({'status': False, 'message': result})

    return render_template('download.html')



if __name__ == '__main__':
    authtoken = input("Enter your ngrok authtoken: ")

    ngrok.set_auth_token(authtoken) # Set the authtoken dynamically
    
    http_tunnel = ngrok.connect(9000, options={"bind_tls": True})
    ip = str(http_tunnel.public_url)
    print("Public URL:", ip)
   
    peerWallet = input("Please enter your wallet address: ")
    
    allPeers = contract.functions.getAllPeerWallets().call()
    

    if peerWallet not in allPeers:
        print("Welcome New Peer")
        storage = int(input("Enter the amount of storage (MB) you are willing to share: "))

        gas_estimate = contract.functions.registerPeer(ip, peerWallet, storage).estimate_gas()

        transaction = contract.functions.registerPeer(ip, peerWallet, storage).build_transaction({
            'from': contractVariables['billingAddress'],
            'gas': gas_estimate+10,
            'gasPrice': w3.to_wei('20', 'gwei'),
            'nonce': w3.eth.get_transaction_count(contractVariables['billingAddress']),
        })

    else: 
        print("Updating IP")
        gas_estimate = contract.functions.updateIP(peerWallet, ip).estimate_gas()

        transaction = contract.functions.updateIP(peerWallet, ip).build_transaction({
            'from': contractVariables['billingAddress'],
            'gas': gas_estimate+10,
            'gasPrice': w3.to_wei('20', 'gwei'),
            'nonce': w3.eth.get_transaction_count(contractVariables['billingAddress']),
        })

    signed_transaction = w3.eth.account.sign_transaction(transaction, private_key= contractVariables['privateKey'])
    transaction_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)

    transaction_receipt = w3.eth.wait_for_transaction_receipt(transaction_hash)



    app.run(port=9000)
  


   


