// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../contracts/OpenLabNFT.sol";

contract ListingSetup is DSTest {
    function testOpenLabNFT() public {
        OpenLabNFT nft = new OpenLabNFT();

        // keccak256(bytes()) is how you compare strings in solidity
        require(
            keccak256(bytes(nft.name())) == keccak256(bytes("OpenLab NFT")),
            "name() failed"
        );
        require(
            keccak256(bytes(nft.symbol())) == keccak256(bytes("OLNFT")),
            "symbol() failed"
        );
    }
}
