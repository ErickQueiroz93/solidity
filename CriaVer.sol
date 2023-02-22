// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "EIP4973.sol";

contract CRIAVer is ERC4973 {
    address public owner;
    uint256 public count = 0;
    uint256 public countAnalyze = 0;

    using Address for address;
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private id;

    mapping(address => uint256) private addressMintedBalance;
    mapping(uint256 => uint) private _availableTokens;
    mapping(uint256 => string) private uris;

    mapping(address => address) private walletsOwner;

    string private baseURI;
    string private _contractUri;

    uint256 private maxSupply = 1000000;
    uint256 private maxMintAmount = 1;
    uint256 private _nftEtherValue = 0;

    bool private paused = false;
    
    address _contractOwner;

    mapping(uint256 => Influencer) private hashToInfluencer;

    struct Influencer {
        address wallet;
        string instagram;
        string linkedin;
        string facebook;
        string name;
        string user;
    }

    mapping(uint256 => InfluencerChecked) private hashToInfluencerChecked;

    struct InfluencerChecked {
        address wallet;
        string instagram;
        string linkedin;
        string facebook;
        string name;
        string user;
    }

    event Verification(address wallet, string instagram, string linkedin, string facebook, uint256 idToken, string name, string user);
    event Analyze(address wallet, string instagram, string linkedin, string facebook, string name);

    constructor () ERC4973("Criador Verificado", "CRIAVer", "CRIAVer") {
        owner = msg.sender;
        _contractUri = "https://ipfs.io/ipfs/QmXzVBswRdGCd9tMggAS7ZACEvHXCEHTFuYqMf85oHDMaR";
        _contractOwner = msg.sender;
        walletsOwner[msg.sender] = msg.sender;
    }

    function burn(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender || msg.sender == owner, "You can't revoke this token");
        _burn(_tokenId);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public {
        require(walletsOwner[msg.sender] == msg.sender, "Only wallets with permission");
        baseURI = _newBaseURI;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public {
        require(walletsOwner[msg.sender] == msg.sender, "Only wallets with permission");
        maxMintAmount = _maxMintAmount;
    }

    function pause(bool _state) public {
        require(walletsOwner[msg.sender] == msg.sender, "Only wallets with permission");
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
    }

    function setMaxSupply(uint256 _maxSupply) public {
        require(walletsOwner[msg.sender] == msg.sender, "Only wallets with permission");
        maxSupply = _maxSupply;
    }

    function setNftEtherValue(uint256 nftEtherValue) public {
        require(walletsOwner[msg.sender] == msg.sender, "Only wallets with permission");
        _nftEtherValue = nftEtherValue;
    }

    function getMaxSupply() public view returns (uint) {
        return maxSupply;
    }

    function getNftEtherValue() public view returns (uint) {
        return _nftEtherValue;
    }

    function getMaxMintAmount() public view returns (uint256) {
        return maxMintAmount;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    function totalSupply() public view returns (uint256) {
        return count;
    }

    function verifiedProfile(string memory uri, address payable endUser, string memory instagram, string memory linkedin, string memory facebook, string memory name, string memory user) public {
        uint256 _mintAmount = 1;
        uint256 supply = totalSupply();

        require(walletsOwner[msg.sender] == msg.sender, "Only wallets with permission");
        require(!paused, "Contrato pausado");
        require(_mintAmount > 0, "Precisa verificar pelo menos 1 wallet");
        require(_mintAmount + balanceOf(endUser) <= maxMintAmount, "Quantidade limite de verificacao por wallet excedida");
        require(supply + _mintAmount <= maxSupply, "Quantidade limite de verificacao excedida");

        uint256 updatedNumAvailableTokens = maxSupply - totalSupply();

        id.increment();
        uint256 Id = id.current();

        addressMintedBalance[endUser]++;
        _mint(owner, endUser, Id, uri);

        count = Id;

        uris[Id] = uri;
        emit Verification(endUser, instagram, linkedin, facebook, Id, name, user);

        InfluencerChecked storage postChecked = hashToInfluencerChecked[Id];

        postChecked.wallet = endUser;
        postChecked.instagram = instagram;
        postChecked.linkedin = linkedin;
        postChecked.facebook = facebook;
        postChecked.name = name;
        postChecked.user = user;

        hashToInfluencerChecked[Id] = postChecked;

        tokenURI(Id);
        --updatedNumAvailableTokens;

        split(_mintAmount);
    }

    function _setTokenURI(uint256 tokenId, string memory uri, address payable endUser, string memory instagram, string memory linkedin, string memory facebook, string memory name, string memory user) public {
        require(walletsOwner[msg.sender] == msg.sender, "Only wallets with permission");
        
        setTokenURI(tokenId, uri);
        uris[tokenId] = uri;

        InfluencerChecked storage postChecked = hashToInfluencerChecked[tokenId];

        postChecked.wallet = endUser;
        postChecked.instagram = instagram;
        postChecked.linkedin = linkedin;
        postChecked.facebook = facebook;
        postChecked.name = name;
        postChecked.user = user;

        hashToInfluencerChecked[tokenId] = postChecked;
    }

    function analyzeProfile(address payable endUser, string memory instagram, string memory linkedin, string memory facebook, string memory name) public {
        uint256 _mintAmount = 1;
        uint256 supply = totalSupply();

        require(walletsOwner[msg.sender] == msg.sender, "Only wallets with permission");
        require(!paused, "Contrato pausado");
        require(_mintAmount > 0, "Precisa verificar pelo menos 1 wallet");
        require(_mintAmount + balanceOf(endUser) <= maxMintAmount, "Quantidade limite de verificacao por wallet excedida");
        require(supply + _mintAmount <= maxSupply, "Quantidade limite de verificacao excedida");

        countAnalyze += 1;

        Influencer storage post = hashToInfluencer[countAnalyze];

        post.wallet = endUser;
        post.instagram = instagram;
        post.linkedin = linkedin;
        post.facebook = facebook;
        post.name = name;

        hashToInfluencer[countAnalyze] = post;

        emit Analyze(endUser, instagram, linkedin, facebook, name);
    }

    function getAnalyseProfile(uint256 idStatus) public view returns (address, string memory, string memory, string memory, string memory) {
      return (hashToInfluencer[idStatus].wallet, hashToInfluencer[idStatus].instagram, hashToInfluencer[idStatus].linkedin, hashToInfluencer[idStatus].facebook, hashToInfluencer[idStatus].name);
    }

    function getInfluencer(uint256 idStatus) public view returns (address, string memory, string memory, string memory, string memory, string memory) {
      return (hashToInfluencerChecked[idStatus].wallet, hashToInfluencerChecked[idStatus].instagram, hashToInfluencerChecked[idStatus].linkedin, hashToInfluencerChecked[idStatus].facebook, hashToInfluencerChecked[idStatus].name, hashToInfluencerChecked[idStatus].user);
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function setContractURI(string memory contractURI_) external {
        require(walletsOwner[msg.sender] == msg.sender, "Only wallets with permission");
        _contractUri = contractURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = uris[tokenId];
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI)) : "";
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint)
    {
        return addressMintedBalance[_owner];
    }

    function setWalletPermission(address _owner) external onlyOwner {
        walletsOwner[_owner] = _owner;
    }

    function checkPermission(address _owner) public view returns (bool) {
        if (walletsOwner[_owner] == _owner) {
            return true;
        } else {
            return false;
        }
    }

    function split(uint256 _mintAmount) public payable {
        uint256 _nftEtherValueTemp = _nftEtherValue;
        if (_nftEtherValue > 0) {
            require(msg.value >= (_nftEtherValueTemp * _mintAmount), "Valor da mintagem diferente do valor definido no contrato");
            payable(_contractOwner).transfer(msg.value);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
}
