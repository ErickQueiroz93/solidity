// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";
import "https://github.com/ErickQueiroz93/solidity/blob/main/ERC721A.sol";

contract Admissao is DefaultOperatorFilterer, ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private id;

    uint256 public maxSupplyMonthly = 500;
    uint256 public maxSupplyYearly = 500;
    uint256 private maxMintAmount = 500;
    
    bool public paused = false;
    
    string private contractUri;
    
    address public contractOwner;

    uint256 private royalties = 7;
    uint256 private royaltiesMetaEXP = 42;
    uint256 private royaltiesBrazuera = 41;
    uint256 private royaltiesPool = 10;

    uint256 public nftValueMonthly = 1000000000000000000;
    uint256 public nftValueYearly = 2000000000000000000;

    uint256 public contNftsMonthly = 0;
    uint256 public contNftsYearly = 0;

    address private wMobiup = 0x8E666a4747EDb83A21b511Ea381edBcCe1CdD300;
    address private wMetaEXP = 0x922334dbFeC8AcaD892009af5e8F436CC6C48295;
    address private wBrazuera = 0x1407c70d2AD71173384894EEaa4E89Ae1bbB5D22;
    address private wPool = 0xe16CB16f4142366C0258F627Afd9B3750a37883f;

    mapping(uint256 => string) private cids;

    constructor() ERC721A("Brazuera - A Admissao", "ADMISSAO") {
        contractUri = "_contractURI";
        contractOwner = msg.sender;
    } 

    function price(uint8 _typeFlat) public view returns (uint256) {
        if (_typeFlat == 1) {
            return nftValueMonthly;
        } else {
            return nftValueYearly;
        }
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setNftValueMonthly(uint256 value) public onlyOwner {
        nftValueMonthly = value;
    }

    function setNftValueYearly(uint256 value) public onlyOwner {
        nftValueYearly = value;
    }

    function mintMonthly(uint256 _mintAmount, address payable _endUser, string memory _cid) public payable {
        require(!paused, "O contrato pausado");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Precisa mintar pelo menos 1 NFT");
        require(_mintAmount + balanceOf(_endUser) <= maxMintAmount, "Quantidade limite de mint por carteira excedida");
        require(supply + _mintAmount <= maxSupplyMonthly, "Quantidade limite de NFT excedida");
        
        split(_mintAmount, 1);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_endUser, 1);
            id.increment();
            uint256 Id = id.current();
            cids[Id] = _cid;
            contNftsMonthly++;
        }
    }

    function mintYearly(uint256 _mintAmount, address payable _endUser, string memory _cid) public payable {
        require(!paused, "O contrato pausado");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Precisa mintar pelo menos 1 NFT");
        require(_mintAmount + balanceOf(_endUser) <= maxMintAmount, "Quantidade limite de mint por carteira excedida");
        require(supply + _mintAmount <= maxSupplyYearly, "Quantidade limite de NFT excedida");
        
        split(_mintAmount, 2);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_endUser, 1);
            id.increment();
            uint256 Id = id.current();
            cids[Id] = _cid;
            contNftsYearly++;
        }
    }

    function contractURI() external view returns (string memory) {
        return contractUri;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractUri = _contractURI;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = cids[tokenId];
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI)) : "";
    }

    function split(uint256 _mintAmount, uint8 _typeFlat) public payable {
        uint256 _nftEtherValueTemp = price(_typeFlat);

        require(msg.value >= (_nftEtherValueTemp * _mintAmount), "Valor da mintagem diferente do valor definido no contrato");

        uint256 amountM = msg.value * royalties / 100;
        payable(wMobiup).transfer(amountM);

        uint256 amountMetaExp = msg.value * royaltiesMetaEXP / 100;
        payable(wMetaEXP).transfer(amountMetaExp);

        uint256 amountBrazuera = msg.value * royaltiesBrazuera / 100;
        payable(wBrazuera).transfer(amountBrazuera);
        
        payable(wPool).transfer(address(this).balance);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function destroy() public onlyOwner {
        require(msg.sender == contractOwner, "Only the owner can destroy the contract");
        selfdestruct(payable(contractOwner));
    }

    function burn(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender || msg.sender == contractOwner, "You can't revoke this token");
        _burn(_tokenId);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        uint256 amountMetaExp = msg.value * 50 / 100;
        payable(wMetaEXP).transfer(amountMetaExp);

        payable(wBrazuera).transfer(address(this).balance);
    }
}
