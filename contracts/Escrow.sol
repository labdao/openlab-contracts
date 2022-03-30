// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Exchange.sol";
import "./OpenLabNFT.sol";


// probably shouldn't inherit these

contract Escrow is Exchange, OpenLabNFT {
  address payable public arbiter;

  // Add LabDAO multisig address
  address payable public labDao;

  mapping (uint => uint) public jobCosts;

  // Event for receiving funds
  event Received(address, uint);

  // constructor (address payable _client, address payable _provider, address payable _arbiter, address payable _labDaoMultiSig) public {
  //   client = _client;
  //   provider = _provider;
  //   arbiter = _arbiter;
  //   labDao = _labDaoMultiSig;
  // }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function swap(uint jobId, string memory tokenURI) external payable isValidJob(jobId) isActiveJob(jobId) {
    address client = Exchange.jobsList[jobId].client;
    address provider = Exchange.jobsList[jobId].provider;

    // 95% sent to provider
    uint providerRevenue = Exchange.jobsList[jobId].jobCost * 19 / 20;
    // 5% sent to LabDAO
    uint marketRevenue = Exchange.jobsList[jobId].jobCost / 20;

    // Send NFT to client
    OpenLabNFT.safeMint(client, tokenURI);

    // Send Ether to provider and LabDAO
    sendViaCall(payable(provider), providerRevenue);
    sendViaCall(payable(labDao), marketRevenue);

    // close job
    closeJob(jobId);
  }

  // When a job is cancelled, funds should be returned to the client
  function returnFunds(uint jobId) external payable isValidJob(jobId) isActiveJob(jobId) {
    sendViaCall(Exchange.jobsList[jobId].client, Exchange.jobsList[jobId].jobCost);
    cancelJob(jobId);
  }

  // function sendFunds(address payable _to, uint amount) override public payable {
  //   (bool success, bytes memory data) = _to.call{value: amount}("");
  //   require(success, "Failed to send Ether");
  // }
}
