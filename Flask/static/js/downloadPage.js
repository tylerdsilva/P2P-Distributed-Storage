async function getWalletNumber() {
    if (window.ethereum) {
        try {
            await window.ethereum.request({ method: 'eth_requestAccounts' });
            const web3 = new Web3(window.ethereum);
            const accounts = await web3.eth.getAccounts();
            return accounts;
      } 
      catch (err) {
        console.error(err);
        return null;
        //user didnt give permission to wallet
      }
    } 
    else {
        console.log("Non-Ethereum browser detected. You should consider installing MetaMask.");
        return null;
    }
}


async function submitDownload() {
    try {
        const accounts = await getWalletNumber();
        console.log(accounts[0]);
        hash = document.getElementById("hash").value;
        
        const response = await fetch('/download', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({hash: hash, account: accounts[0]})
        });
          
        if (!response.ok) {
            throw new Error('Failed to download file');
        }
        
        const data = await response.json();

    
        if (data.status == true){
            const file_data = window.atob(data.filedata);
            const array = new Uint8Array(file_data.length);
            for (let i = 0; i < file_data.length; i++) {
                array[i] = file_data.charCodeAt(i);
            }
            const blob = new Blob([array], { type: 'application/octet-stream' });
            const url = window.URL.createObjectURL(blob);
            
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', data.filename);
            
            document.body.appendChild(link);
            link.click();
            link.remove();
        }
    
        window.location.replace("/error?message=File%20Lost.");

    } catch (err) {
      console.error(err);
      // Handle the case where the user denies permission or cancels the request
    }
  }