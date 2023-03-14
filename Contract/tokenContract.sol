// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StoreT {
    string public name = "storeT";
    string public symbol = "STRT";
    uint256 public decimals = 6;
    uint256 public totalSupply = 100000 * (10 ** decimals);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address public owner;

    struct FileInfo {
        bytes32 hash;
        string fileName;
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
        bytes32 key;
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

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[msg.sender], "Insufficient balance.");
        require(_to != address(0), "Invalid recipient address.");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from], "Insufficient balance.");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance.");
        require(_to != address(0), "Invalid recipient address.");

        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    function burn(address owner, uint256 value) public returns (uint256) {
        require(balances[owner] >= value, "Insufficient balance");
        balances[owner] -= value;
        return balances[owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
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
        transfer(_wallet, _storage);
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

    function locateFile(bytes32 _hash, string memory fileName, address _owner) public view returns (string memory) {
        for (uint i = 0; i < fileInfos.length; i++) {
            // find the file with the same hash
            if (fileInfos[i].hash == _hash) {
                for (uint j = 0; j < peerInfos.length; i++) {
                    // find peer with the same wallet
                    if (peerInfos[i].wallet == fileInfos[i].peerWallet) {
                        if (peerInfos[i].isAlive) {
                            return peerInfos[i].ip;
                        } else {
                            return "Peer is down";
                        }
                    }
                }
            }
        }
        return "File not found";
    }
    function authenticate(bytes32 hash, string memory fileName, address ownerWallet, address peerWallet) public view returns (string memory) {
        for (uint i = 0; i < fileInfos.length; i++) {
            if (fileInfos[i].hash == hash) {
                if (fileInfos[i].ownerWallet != ownerWallet) {
                    return "You are not the owner";
                }
                if (fileInfos[i].peerWallet != peerWallet) {
                    return "Wrong peer/IP address";
                }
                return "True";
            }
        }
        return "File not found";
    }   

    function reserveStorage(address account, uint256 capacity) public returns (bytes32 key, string memory ip) {
        require(capacity > 0, "Capacity must be greater than 0.");

        // Check account balance and deduct tokens
        require(balances[account] >= capacity, "Insufficient balance.");
        balances[account] -= capacity;

        // Find an alive peer with enough storage capacity
        uint256 remainingStorage = capacity;
        for (uint256 i = 0; i < peerInfos.length; i++) {
            if (peerInfos[i].isAlive && peerInfos[i].availableStorage >= remainingStorage) {
                ip = peerInfos[i].ip;
                peerInfos[i].availableStorage -= remainingStorage;

                // Generate a random key
                key = keccak256(abi.encodePacked(block.timestamp, msg.sender, i, remainingStorage));

                // Add the key to the list
                KeyInfo memory newKey = KeyInfo(ip, key, msg.sender, address(0), int256(remainingStorage));
                keysList.push(newKey);

                // Return the key and IP address of the peer
                return (key, ip);
            }
        }

        // No available peers found
        balances[account] += capacity;
        revert("No available peers found.");
    }
    
    function storeFile(bytes32 hash, string memory fileName, bytes32 key, address peerWallet, address ownerWallet, int fileSize) public returns (string memory) {
        require(peerWallet != address(0), "Invalid peer wallet address");
        require(ownerWallet != address(0), "Invalid owner wallet address");
        require(fileSize > 0, "Invalid file size");

        for (uint i = 0; i < keysList.length; i++) {
            if (keysList[i].key == key) {
                if (keysList[i].ownerWallet != ownerWallet) {
                    return "Owner wallet mismatch";
                }
                if (keysList[i].peerWallet != peerWallet) {
                    return "Peer wallet mismatch";
                }
                if (keysList[i].size < fileSize) {
                    return "File size mismatch";
                }
                
                FileInfo memory newFileInfo = FileInfo(hash, fileName, ownerWallet, peerWallet, fileSize);
                fileInfos.push(newFileInfo);
                delete keysList[i];
                return "True";
            }
        }
        return "Key not found";
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


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
