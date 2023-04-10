# CMPT756-DistributedStorage

# Overview
Our project utilizes an Ethereum smart contract to implement a decentralized storage system. Peers can register to our system to provide storage space in exchange for tokens. These tokens, in turn, can be used by users to safely store files within the peer-to-peer network. The refined system is now composed of a few different components that work together to form the distributed file storage system:

* **MetaMask:** MetaMask is used to manage user wallets. It allows users to access their Ethereum wallet through a browser extension or mobile app, which can then be used to interact with our token.

* **Smart Contract:** As discussed in the previous report, the smart contract is responsible for managing the metadata necessary for the distributed system. It maintains records of peers, users, IP addresses, files names, file sizes, etc. This contract has been modified from our 
previous design and takes on more responsibility (see ‘Implementation’ section). 

* **Remix IDE:** Our system is founded on using the Remix IDE for the deployment of the smart contract. It is a good medium for testing any immediate errors that exist in the .sol file. 

* **Ngrok:** Ngrok is a tunneling package that we are using to hide our peer ip addresses and still allow clients to connect to a peer machine to facilitate file transfer. 

* **Flask Implementation:** The flask app provides a UI to the client connected to a peer to upload or download files. All authentication with the smart contract happens here using web3 packages. 

# Components on Git
