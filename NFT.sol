// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "ERC721A.sol";

contract NFT is ERC721A {
    constructor() ERC721A("NFT TESTE", "NFTv1") {}

    function mint(uint8 qtde) public {
        _safeMint(msg.sender, qtde, '');
    }
}
