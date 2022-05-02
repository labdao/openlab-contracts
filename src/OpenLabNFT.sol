// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OpenLabNFT is ERC721, ERC721URIStorage {

  // ---------------------------- State Management ---------------------------------------- //
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  // ---------------------------- Constructor ---------------------------------------- //
  constructor() ERC721("OpenLab NFT", "OLNFT") {}

  function _baseURI() internal pure override returns (string memory) {
    // base URI points to IPFS, then we append the CID 
    return "ipfs://";
  }

  // ---------------------------- Events for Subgraph --------------------------------- //

  event tokenCreated(uint256 indexed _tokenId, string _tokenURI);

  // NOTE: add modifier so only validated provider can call this function

  // revisit this so only can be called by Exchange
  function safeMint(address _to, string memory _tokenURI) external {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(_to, tokenId);
    _setTokenURI(tokenId, _tokenURI);

    emit tokenCreated(tokenId, _tokenURI);
  }

  // ---------------------------- Overrides ----------------------------------------//
  // @dev Overrides required by Solidity

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }
}

interface IOpenLabNFT {
  function safeMint(address _to, string memory _tokenURI) external;
}