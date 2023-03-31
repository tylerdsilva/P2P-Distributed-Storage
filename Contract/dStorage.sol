// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StoreT {
    string public name = "storeT";
    string public symbol = "STRT";
    uint256 public decimals = 0;
    uint256 public totalSupply = 100000 * (10 ** decimals);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address public owner;
    
    uint256 baseKey = 467453;

    struct FileInfo {
        string hash;
        address ownerWallet;
        address peerWallet;
        int fileSize;
    }

    struct PeerInfo {
        string ip;
        address wallet;
        uint256 availableStorage;
        bool isAlive;
    }

    struct KeyInfo {
        string ip;
        uint256 key;
        address ownerWallet;
        address peerWallet;
        int size;
    }

    FileInfo[] public fileInfos;
    PeerInfo[] public peerInfos;
    KeyInfo[] public keysList;


  
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    


    function balance() public view returns (uint256 balance) {
        return balances[msg.sender];
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function burn(address wallet, uint256 value) public returns (uint256) {
        require(balances[wallet] >= value, "Insufficient balance");
        balances[wallet] -= value ;
        return balances[wallet];
    }

    function registerPeer(string memory _ip, address _wallet, uint256 _storage) public returns (string memory) {
        // Check if peer already exists by wallet address
        for (uint i = 0; i < peerInfos.length; i++) {
            if (peerInfos[i].wallet == _wallet) {
                return "Wallet already exists";
            }
        }

        // Peer does not exist, add it to the list
        PeerInfo memory newPeerInfo = PeerInfo(_ip, _wallet, _storage, true);
        peerInfos.push(newPeerInfo);

        // Transfer tokens to the new peer's wallet
        balances[_wallet] += _storage ;
        return "True";
    }

    function updateIP(address wallet, string memory ip) public returns (bool) {
        for (uint i = 0; i < peerInfos.length; i++) {
            if (peerInfos[i].wallet == wallet) {
                peerInfos[i].ip = ip;
                peerInfos[i].isAlive = true;
                return true; //updated with ip and isAlive for that wallet
            }
        }
        return false; //wallet does not exist
    }

    function locateFile(string memory _hash) public view returns (string memory IP) {
        for (uint i = 0; i < fileInfos.length; i++) {
            // find the file with the same hash
            if (keccak256(bytes(fileInfos[i].hash)) == keccak256(bytes(_hash))) {
                if (fileInfos[i].ownerWallet != msg.sender){
                    return "You are not the owner";
                }
   
                for (uint j = 0; j < peerInfos.length; i++) {
                    // find peer with the same wallet
                    if (peerInfos[j].wallet == fileInfos[i].peerWallet) {
                        if (peerInfos[j].isAlive) {
                            return  string.concat(peerInfos[j].ip,  "/download");
                        } else {
                            return "Peer is down";
                        }
                    }
                }
            }
        }
        return "File not found";
    }
    function authenticate(string memory hash, address ownerWallet, address peerWallet) public view returns (string memory) {
        for (uint i = 0; i < fileInfos.length; i++) {
            if  (keccak256(bytes(fileInfos[i].hash)) == keccak256(bytes(hash)))  {
                if (fileInfos[i].ownerWallet != ownerWallet) {
                    return "You are not the owner.";
                }
                if (fileInfos[i].peerWallet != peerWallet) {
                    return "Wrong peer/IP address.";
                }
                return "True";
            }
        }
        return "File not found.";
    }   
    
    function reserveStorage(uint256 capacity) public returns(uint256, string memory) {
        require(capacity > 0, "Capacity must be greater than 0.");

        // Check account balance and deduct tokens
        require(balances[msg.sender] >= capacity , "Insufficient balance.");
 

        // Find an alive peer with enough storage capacity
    
        for (uint256 i = 0; i < peerInfos.length; i++) {
            if (peerInfos[i].isAlive && peerInfos[i].availableStorage >= capacity) {
                string memory ip = peerInfos[i].ip ;
                

                // Generate a random key
                uint256 key = baseKey;
                baseKey = baseKey + 3; 
                

                // Add the key to the list
                KeyInfo memory newKey = KeyInfo(ip, key, msg.sender, peerInfos[i].wallet, int256(capacity));
                
                balances[msg.sender] -= capacity ;
                peerInfos[i].availableStorage -= capacity;
                keysList.push(newKey);

                // Return the key and IP address of the peer
                return (key, ip);
            }
        }

        // No available peers found

        revert("No available peers found.");
    }

    function getLastKey() public view returns(uint256 Key, string memory IP) {
        for (uint256 i = keysList.length-1; i >= 0; i--)
            if (keysList[i].ownerWallet == msg.sender)
                return (keysList[i].key,  string.concat(keysList[i].ip,  "/upload"));
        return (0, "You have no active keys");

    }

    function authenticateKey(uint256 key, address peerWallet, address ownerWallet, int fileSize) public view returns (uint256, string memory) {
        require(peerWallet != address(0), "Invalid peer wallet address");
        require(ownerWallet != address(0), "Invalid owner wallet address");
        require(fileSize > 0, "Invalid file size");
        
        for (uint i = 0; i < keysList.length; i++) {
            if (keysList[i].key == key)  {
                if (keysList[i].ownerWallet != ownerWallet) {
                    return (0, "Owner wallet mismatch.");
                }
                if (keysList[i].peerWallet != peerWallet) {
                    return (0, "Wrong Peer");
                }
                if (keysList[i].size < fileSize) {
                    return (0, "File size mismatch.");
                }
                
                return (i, "Key Found.");
            }
        }
        return (0,"Invalid Key.");
        
    }  


    function storeFile(string memory hash, uint256 key, address peerWallet, address ownerWallet, int fileSize) public returns (string memory) {
        require(peerWallet != address(0), "Invalid peer wallet address");
        require(ownerWallet != address(0), "Invalid owner wallet address");
        require(fileSize > 0, "Invalid file size");
        
        for (uint i = 0; i < keysList.length; i++) {
            if (keysList[i].key == key)  {
                if (keysList[i].ownerWallet != ownerWallet) {
                    return "Owner wallet mismatch";
                }
                if (keysList[i].peerWallet != peerWallet) {
                    return "Peer wallet mismatch";
                }
                if (keysList[i].size < fileSize) {
                    return "File size mismatch";
                }
                
                FileInfo memory newFileInfo = FileInfo(hash, ownerWallet, peerWallet, fileSize);
                fileInfos.push(newFileInfo);
                delete keysList[i];
                return "True";
            }
        }
        return "Key not found";
    }

    function getAllPeerWallets() public view returns (address[] memory) {
        address[] memory peerWallets = new address[](peerInfos.length);
        
        for (uint256 i = 0; i < peerInfos.length; i++) {
            peerWallets[i] = peerInfos[i].wallet;
        }
        
        return peerWallets;
    }

    function getPeerInfos() public view returns (PeerInfo[] memory) {
        return peerInfos;
    }
    function getKeyslist() public view returns (KeyInfo[] memory) {
        return keysList;
    }
    function getFileInfos() public view returns (FileInfo[] memory) {
        return fileInfos;
    }
    function clearAll() public {
        // Clear all fileInfos
        while (fileInfos.length > 0) {
            delete fileInfos[fileInfos.length - 1];
            fileInfos.pop();
        }

        // Clear all peerInfos
        while (peerInfos.length > 0) {
            delete peerInfos[peerInfos.length - 1];
            peerInfos.pop();
        }

        // Clear all keysList
        while (keysList.length > 0) {
            delete keysList[keysList.length - 1];
            keysList.pop();
        }
    }   


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}
