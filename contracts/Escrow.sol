// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Exchange.sol";
import "./OpenLabNFT.sol";

contract Escrow is Exchange, OpenLabNFT {
  address payable public client;
  address payable public provider;
  address payable public arbiter;
  address payable public labDao;

  mapping (uint => uint) public jobCosts;

  // constructor (address payable _client, address payable _provider, address payable _arbiter, address payable _labDaoMultiSig) public {
  //   client = _client;
  //   provider = _provider;
  //   arbiter = _arbiter;
  //   labDao = _labDaoMultiSig;
  // }

  

  // function depositFunds(uint jobId) external payable isValidJob(jobId) isActiveJob(jobId) {
  //   jobCosts[jobId] = 
  // }

  function depositNFT(uint jobId) public isValidJob(jobId) isActiveJob(jobId) {
    // receives minted NFT
  }

  fallback() external payable {}

  function swap(uint jobId) external payable isValidJob(jobId) isActiveJob(jobId) {
    // send NFT to client

    // send job cost amount to provider
    // NOTE: this needs to be updated since transfer() is not a secure option
    Exchange.jobsList[jobId].provider.transfer(Exchange.jobsList[jobId].jobCost);
    // close job
    closeJob(jobId);
  }
}
