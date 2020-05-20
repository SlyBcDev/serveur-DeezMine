pragma solidity ^0.5.0;

import "./ERC721Full.sol";

contract DeezMine is ERC721Full {
    
  Counters.Counter private _tokenIds;
    
//Variable
  struct instrumentInfo {
      string brand;
      string model;
      string instrumentType;
      uint birthDateOfInstrument;
      string serialNumber;
   }

  mapping (string => uint) public hashToTokenId;
  mapping (uint => instrumentInfo) public instrument;
  mapping (uint => bool) public isStolenOrLost;
  
  mapping (uint => string[]) public pictures;
  mapping (uint => uint) public numberOfPictures;
    
  mapping (uint => string[]) public storieOfInstrument;
  mapping (uint => uint) public numberOfStories;
  
  mapping (address => bool) public _isAdmin;
  mapping (address => bool) public _isCertifier;
  mapping (address => bool) _canTransferTokenFromContract;

  event newInstrument(uint indexed _id, string _brand, string _serialNumber, address indexed _certifier); 
  event newOwner(uint indexed _id, uint date, address _newOwnerAddress);
  event hasBeenStolenOrLost(uint indexed _id, uint date, string _message);
  event hasBeenRecover(uint indexed _id, uint date, string _message);
  event warningAlarm(uint indexed _id, uint date, string _location);
  event historyEvent(uint indexed _id,uint _date, string _details);

    // Modifier
 
    modifier isOwner(string memory _hashUidNfcTag) {
    uint _tokenId = hashToTokenId[_hashUidNfcTag]; 
    require(ownerOf(_tokenId) == msg.sender);
    _;
    }
    
    modifier canTransferTokenFromContract(address _asker){
        require(_canTransferTokenFromContract[_asker]==true);
        _;
    }
    
    modifier isAdmin(address _admin){
        require(_isAdmin[_admin]==true);
        _;
    }
    
    modifier isCertifier(address _certifier){
        require(_isCertifier[_certifier]==true);
        _;
    }

    constructor() ERC721Full("DeezMine", "DZM") public{
    _isAdmin[msg.sender]=true;
    _isCertifier[msg.sender]=true;
    _canTransferTokenFromContract[msg.sender]=true;
    }
    
    //-------------------------------------------------------------------------//
    //----------------------Fonction d'administration--------------------------//
    //-------------------------------------------------------------------------//
    
    function addAdmin(address _newAdmin) public isAdmin(msg.sender) {
        _isAdmin[_newAdmin]=true;
    }
    
    function addCertifier(address _newCertifier) public isAdmin(msg.sender){
        _isCertifier[_newCertifier]=true;
    }
    
    function addUserCanTransferTokenFromContract(address _newCanTransferTokenFromContract) public isAdmin(msg.sender) {
        _canTransferTokenFromContract[_newCanTransferTokenFromContract]=true;
    }
    
    function deleteAdmin(address _oldAdmin) public isAdmin(msg.sender) isAdmin(_oldAdmin){
        require(_oldAdmin != msg.sender);
        _isAdmin[_oldAdmin]=false;
    }
    
    function deleteCertifier(address _oldCertifier) public isAdmin(msg.sender) isCertifier(_oldCertifier){
        _isCertifier[_oldCertifier]=false;
    }
    
     function deleteUserCanTransferTokenFromContract(address _oldCanTransferTokenFromContract) public isAdmin(msg.sender) canTransferTokenFromContract(_oldCanTransferTokenFromContract){
        _canTransferTokenFromContract[_oldCanTransferTokenFromContract]=false;
    }
    
    //-------------------------------------------------------------------------//
    //--------------Enregistrement et transfer de l'instrument-----------------//
    //-------------------------------------------------------------------------//

  function checkInBrandNewInstrument(
    string memory _brand,
    string memory _model,
    string memory _instrumentType,
    string memory _serialNumber,
    string memory _picture1,
    string memory _picture2,
    string memory _picture3,
    string memory _hashUidNfcTag
    ) public isCertifier(msg.sender){
        require(hashToTokenId[_hashUidNfcTag]==0);
        _tokenIds.increment();

        uint256 _newItemId = _tokenIds.current();
        hashToTokenId[_hashUidNfcTag] = _newItemId;
        
        _mint(address(this), _newItemId);
        
        instrument[_newItemId].brand = _brand;
        instrument[_newItemId].model = _model;
        instrument[_newItemId].instrumentType = _instrumentType;
        instrument[_newItemId].birthDateOfInstrument = now;
        instrument[_newItemId].serialNumber = _serialNumber;
        numberOfPictures[_newItemId] = numberOfPictures[_newItemId].add(3);
        pictures[_newItemId].push(_picture1);
        pictures[_newItemId].push(_picture2);
        pictures[_newItemId].push(_picture3);

        emit newInstrument(_newItemId,_brand,_serialNumber,msg.sender);

    }
    
  function checkInNotNewInstrument(
    string memory _brand,
    string memory _model,
    string memory _instrumentType,
    string memory _serialNumber,
    string memory _picture,
    string memory _hashUidNfcTag,
    uint _estimateDate
    ) public isCertifier(msg.sender){
        require(hashToTokenId[_hashUidNfcTag]==0);
        _tokenIds.increment();

        uint256 _newItemId = _tokenIds.current();
        hashToTokenId[_hashUidNfcTag] = _newItemId;
        
        _mint(address(this), _newItemId);
        
        instrument[_newItemId].brand = _brand;
        instrument[_newItemId].model = _model;
        instrument[_newItemId].instrumentType = _instrumentType;
        instrument[_newItemId].birthDateOfInstrument = _estimateDate;
        instrument[_newItemId].serialNumber = _serialNumber;
        numberOfPictures[_newItemId] = numberOfPictures[_newItemId].add(1);
        pictures[_newItemId].push(_picture);

        //return _newItemId;
        emit newInstrument(_newItemId,_brand,_serialNumber,msg.sender);

    }
    
     function takeOwnership( string memory _hashUidNfcTag, address _futurOwner) public canTransferTokenFromContract(msg.sender) {
        uint _tokenId = hashToTokenId[_hashUidNfcTag];
        _transferFrom(address(this),_futurOwner,_tokenId);
        string memory _story = string(abi.encodePacked("This instrument have a new owner address : ", _addressToString(_futurOwner)));
        createStory(_hashUidNfcTag,_story);
        emit newOwner(_tokenId, now, _futurOwner);
        
    }
    

    
    
    //-------------------------------------------------------------------------//
    //---------------------Déclaration de vol ou de perte----------------------//
    //-------------------------------------------------------------------------//
    
    // Un owner peut déclarer son intrument volé ou perdu. 
    function declareStolenOrLost( string memory _hashUidNfcTag, string memory _message) public isOwner(_hashUidNfcTag){
        uint _tokenId = hashToTokenId[_hashUidNfcTag];
        isStolenOrLost[_tokenId] = true;
        string memory concatNowDetails = string(abi.encodePacked(_uint2str(now), "=>", _message));
        storieOfInstrument[_tokenId].push(concatNowDetails);
        numberOfStories[_tokenId] = numberOfStories[_tokenId].add(1);
        emit hasBeenStolenOrLost(_tokenId,now,_message);
    }
    
    // Le owner est le seul à pouvoir pretendre avoir retrouvé son instrument. 
    function declareRecover( string memory _hashUidNfcTag, string memory _message) public isOwner(_hashUidNfcTag){
        uint _tokenId = hashToTokenId[_hashUidNfcTag];
        isStolenOrLost[_tokenId] = false;
        string memory concatNowDetails = string(abi.encodePacked(_uint2str(now), "=>", _message));
        storieOfInstrument[_tokenId].push(concatNowDetails);
        numberOfStories[_tokenId] = numberOfStories[_tokenId].add(1);
        emit hasBeenRecover(_tokenId, now, _message);
    }
    
        
    //-------------------------------------------------------------------------//
    //------------------------------Utilitaires--------------------------------//
    //-------------------------------------------------------------------------//
    

    // fonction permettant de transformer uint en string
    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    // fonction permettant de transformer une adresse en string
      function _addressToString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
    
        
    //-------------------------------------------------------------------------//
    //----------------------Historique de l'instrument-------------------------//
    //-------------------------------------------------------------------------//


    function createStory ( string memory _hashUidNfcTag , string memory _details) public isCertifier(msg.sender){
        uint _tokenId = hashToTokenId[_hashUidNfcTag];

        string memory concatNowDetails = string(abi.encodePacked(_uint2str(now), "=>", _details));
        storieOfInstrument[_tokenId].push(concatNowDetails);
        numberOfStories[_tokenId] = numberOfStories[_tokenId].add(1);
        emit historyEvent(_tokenId,now,_details);
    }
    


}



 
