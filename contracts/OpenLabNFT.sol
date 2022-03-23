// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Exchange.sol";

contract OpenLabNFT is ERC721, ERC721URIStorage, Exchange, Ownable {

  // ---------------------------- State Management ----------------------------------------//
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  // ---------------------------- Constructor ----------------------------------------//
  constructor() ERC721("OpenLab NFT", "OLNFT") {}

  function _baseURI() internal pure override returns (string memory) {
    // base URI points to IPFS, then we append the CID 
    return "ipfs.io://";
  }

  // NOTE: add modifier so only validated provider can call this function

  function safeMint(address _to, string memory _tokenURI) internal {
    uint tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(_to, tokenId);
    _setTokenURI(tokenId, _tokenURI);
  }


  // NOTE:
  // Complete job SHOULD NOT be done in this contract. We want to mint NFTs and close job in Exchange or Escrow

  // // do we need validation for the tokenURI --> to make sure the JSON is in the expected format?
  // // token-gated closing of jobs
  // function completeJob(uint jobId, address client, string memory tokenURI) isValidJob(jobId) isActiveJob(jobId) isProvider(jobId) public {
  //   // mint and send NFT to client
  //   mint(client);

  //   // update job status to closed
  //   closeJob(jobId);
  //   // withdraw escrow

  // }

  // ---------------------------- Overrides ----------------------------------------//
  // @dev Overrides required by Solidity

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }
}