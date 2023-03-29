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

async function uploadFile() {
    try {
        const accounts = await getWalletNumber();
        const key = document.getElementById("key").value;
        const fileInput = document.getElementById("file-input").files[0];


        const formData = new FormData();


        formData.append("key", key);
        formData.append("account", accounts[0]);
        formData.append("file", fileInput);

        var reply;
        const xhr = new XMLHttpRequest();
        xhr.open("POST", "/upload");
        xhr.upload.addEventListener("progress", function(event) {
            const progressBar = document.querySelector(".progress-bar");
            const percent = (event.loaded / event.total) * 100;
            progressBar.style.width = `${percent}%`;
        });

        
        xhr.addEventListener("load", function() {
            const reply = JSON.parse(xhr.responseText);
            if (reply.status == true){
                window.location.replace("/success");
            }
        });
        xhr.send(formData);
  

    } 
    catch (err) {
        console.error(err);
    }
  }