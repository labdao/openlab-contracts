// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// add unit tests to each of these functions
// if there is a bug we find, add a regression test so we can identify the buggy conditions

contract Exchange {

    // ---------------------------- Constructor ---------------------------------// 

    constructor(uint _index) {
        exchangeIndex = _index;
        isEnabled = true;
    }

    // ------------------------ Job structure ------------------------ //

    struct Job {
        address payable client;
        address payable provider;
        uint jobCost;
        // For now, payments should only be in Ether
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

    uint public exchangeIndex;
    bool public isEnabled;
    bool internal locked;

    mapping (uint => Job) public jobsList;
    mapping (address => bool) public clientAddresses;
    mapping (address => bool) public providerAddresses;
    uint jobIdCount;

    // Events for Graph protocol
    event jobCreated(uint indexed _jobId, address indexed _client, address indexed _provider, uint _jobCost, string _jobURI, JobStatus _status);
    event jobCancelled(uint indexed _jobId, address indexed _client, address indexed _provider, uint _jobCost, string _jobURI, JobStatus _status);
    event jobClosed(uint indexed _jobId, address indexed _client, address indexed _provider, uint _jobCost, string _jobURI, JobStatus _status);

    // Values set by owner of ExchangeFactory
    address public escrowAddress;
    uint public royaltyPercentage = 5;

    // ------------------------ Core functions ------------------------ //

    // ADD address _payableToken
    // client and provider should both sign for a job
    function submitJob(address payable _client, address payable _provider, uint _jobCost, string memory _jobURI) noReentrant enabled public payable {
        // Parameter validation
        require(address(msg.sender) == _client, "Only the client can call this function");
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

        // Send deposited amount to the escrow contract
        sendViaCall(payable(escrowAddress), _jobCost);

        // We emit the event of job creation so that the Graph protocol can be used to index the job
        emit jobCreated(jobIdCount, _client, _provider, _jobCost, _jobURI, job.status);

    }

    function sendViaCall(address payable _to, uint amount) public payable {
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // check visibility
    function closeJob(uint _jobId) internal isValidJob(_jobId) isActiveJob(_jobId) enabled {
        Job memory job = jobsList[_jobId];
        
        job.status = JobStatus.CLOSED;
        // We emit the event of job closing so that the Graph protocol can be updated
        emit jobClosed(_jobId, job.client, job.provider, job.jobCost, job.jobURI, job.status);
    }

    // check visibility
    function cancelJob(uint _jobId) internal isValidJob(_jobId) isActiveJob(_jobId) enabled {
        // Escrow handles returning funds back to client

        Job memory job = jobsList[_jobId];
        jobsList[_jobId].status = JobStatus.CANCELLED;

        // We emit the event of job cancellation so that the Graph protocol can be updated
        emit jobCancelled(_jobId, job.client, job.provider, job.jobCost, job.jobURI, job.status);
    }

    function disableExchange() enabled external {
        isEnabled = false;
    }

    // function readJob(uint jobId) public view isValidJob(jobId) returns (address, address, uint, string memory, JobStatus) {
    //     return (
    //         jobsList[jobId].client, 
    //         jobsList[jobId].provider, 
    //         jobsList[jobId].jobCost, 
    //         // jobsList[jobId].payableToken, 
    //         jobsList[jobId].jobURI,
    //         jobsList[jobId].status
    //     );
    // }

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

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier enabled() {
        require(isEnabled, "Exchange is not enabled");
        _;
    }
}
