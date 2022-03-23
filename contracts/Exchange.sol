// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// add unit tests to each of these functions
// if there is a bug we find, add a regression test so we can identify the buggy conditions

contract Exchange is ReentrancyGuard {

    // ------------------------ Job structure ------------------------ //

    struct Job {
        address payable client;
        address payable provider;
        uint jobCost;
        // address payableToken;
        string jobURI;
        JobStatus status;
    }

    enum JobStatus {
        OPEN,
        CLOSED,
        CANCELLED
    }

    // ------------------------ State ------------------------ //

    mapping (uint => Job) public jobsList;
    mapping (address => bool) public clientAddresses;
    mapping (address => bool) public providerAddresses;
    uint jobIdCount;

    // Events for Graph protocol
    // event jobCreated(address _caller, Job indexed _job);
    event jobCreated(uint indexed _jobId, address indexed _client, address indexed _provider, uint _jobCost, string _jobURI, JobStatus _status);
    event jobCancelled(uint indexed _jobId, address indexed _client, address indexed _provider, uint _jobCost, string _jobURI, JobStatus _status);
    event jobClosed(uint indexed _jobId, address indexed _client, address indexed _provider, uint _jobCost, string _jobURI, JobStatus _status);

    // INSERT ESCROW ADDRESS BELOW
    // address public escrowAddress = ;

    // ------------------------ Core functions ------------------------ //

    // ADD address _payableToken
    // client and provider should both sign for a job
    function submitJob(address payable _client, address payable _provider, uint _jobCost, string memory _jobURI) nonReentrant public {
        // Parameter validation
        require(address(msg.sender) == _client, "Only the client can call this function and submit a job");
        require(_client != _provider, "Client and provider addresses must be different");
        require(address(msg.sender).balance >= _jobCost, "Caller does not have enough funds to pay for the job");

        jobIdCount++;
        Job storage job = jobsList[jobIdCount];

        job.client = _client;
        job.provider = _provider;
        job.jobCost = _jobCost;
        // job.payableToken = _payableToken;
        // get jobURI from CLI
        job.jobURI = _jobURI;
        job.status = JobStatus.OPEN;

        // Validates the client and provider addresses
        clientAddresses[_client] = true;
        providerAddresses[_provider] = true;

        // send deposited amount to the escrow contract
        // NOTE: update from transfer to sendViaCall (see below)
        // NOTE: figure out math for conversion of _jobCost (ETH) to a value that can be passed for the transfer
        // payable(escrowAddress).transfer(msg.value);


        // We emit the event of job creation so that the Graph protocol can be used to index the job
        emit jobCreated(jobIdCount, _client, _provider, _jobCost, _jobURI, job.status);

    }

    // function sendViaCall(address payable _to) public payable {
    //     (bool sent, bytes memory data) = _to.call{value: msg.value}("");
    //     require(sent, "Failed to send Ether");
    // }

    // check visibility
    function closeJob(uint _jobId) internal isValidJob(_jobId) isActiveJob(_jobId) {
        Job memory job = jobsList[_jobId];
        job.status = JobStatus.CLOSED;

        // We emit the event of job closing so that the Graph protocol can be updated
        emit jobClosed(_jobId, job.client, job.provider, job.jobCost, job.jobURI, job.status);
    }

    // check visibility
    function cancelJob(uint _jobId) internal isValidJob(_jobId) isActiveJob(_jobId) {
        Job memory job = jobsList[_jobId];
        jobsList[_jobId].status = JobStatus.CANCELLED;
        // need to return funds from escrow to the client

        // We emit the event of job cancellation so that the Graph protocol can be updated
        emit jobCancelled(_jobId, job.client, job.provider, job.jobCost, job.jobURI, job.status);
    }

    function readJob(uint jobId) public view isValidJob(jobId) returns (address, address, uint, string memory, JobStatus) {
        return (
            jobsList[jobId].client, 
            jobsList[jobId].provider, 
            jobsList[jobId].jobCost, 
            // jobsList[jobId].payableToken, 
            jobsList[jobId].jobURI,
            jobsList[jobId].status
        );
    }

    // create functions to manually add "whitelisted" clients and providers by the multisig
    // this is probably a separate contract that is Ownable and can only be called by multisig

    // ------------------------ Function modifiers ------------------------ //

    modifier isValidJob(uint _jobId) {
        require(jobIdCount > 0 && _jobId > 0 && _jobId <= jobIdCount, "Job ID is not valid");
        _;
    }

    modifier isActiveJob(uint _jobId) {
        require(jobsList[_jobId].status == JobStatus.OPEN, "Job is not open");
        _;
    }

    modifier isClient(uint _jobId) {
        require(jobsList[_jobId].client == msg.sender, "Only the client can call this function");
        _;
    }

    modifier isProvider(uint _jobId) {
        require(jobsList[_jobId].provider == msg.sender, "Only the provider can call this function");
        _;
    }

    modifier isValidClient(address _client) {
        require(clientAddresses[_client], "Client address is not valid");
        _;
    }

    modifier isValidProvider(address _provider) {
        require(providerAddresses[_provider], "Provider address is not valid");
        _;
    }

    constructor() ReentrancyGuard() {}

}
