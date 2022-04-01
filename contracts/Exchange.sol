// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// add unit tests to each of these functions
// if there is a bug we find, add a regression test so we can identify the buggy conditions

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./OpenLabNFT.sol";

contract Exchange {

    // ---------------------------- Constructor ---------------------------------// 

    constructor(address _factoryAddress, address _openLabNFTAddress, uint256 _royaltyPercentage) {
        isEnabled = true;
        factoryAddress = _factoryAddress;
        openLabNFTAddress = _openLabNFTAddress;
        royaltyPercentage = _royaltyPercentage;
    }

    // ------------------------ Job structure ------------------------ //

    struct Job {
        address payable client;
        address payable provider;
        address payableToken;
        uint256 jobCost;
        // jobDeadline
        string jobURI;
        JobStatus status;
        string openLabNFTURI;
    }

    enum JobStatus {
        OPEN,
        ACTIVE,
        CLOSED,
        CANCELLED
    }

    // ------------------------ State ------------------------ //

    bool public isEnabled;
    bool internal locked;

    mapping (uint256 => Job) public jobsList;
    mapping (address => bool) public clientAddresses;
    mapping (address => bool) public providerAddresses;
    uint256 jobIdCount = 0;

    // Events for Graph protocol
    event jobCreated(uint256 indexed _jobId, address indexed _client, address _payableToken, uint256 _jobCost, string _jobURI, JobStatus _status);
    event jobActive(uint256 indexed _jobId, address indexed _client, address indexed _provider, uint256 _jobCost, string _jobURI, JobStatus _status);
    event jobCancelled(uint256 indexed _jobId, address indexed _client, address indexed _provider, uint256 _jobCost, string _jobURI, JobStatus _status);
    event jobClosed(uint256 indexed _jobId, address indexed _client, address indexed _provider, uint256 _jobCost, string _jobURI, JobStatus _status, string _openLabNFTURI);

    event Received(address, uint256);

    address public factoryAddress;

    // Values set by owner of ExchangeFactory
    address public openLabNFTAddress;
    uint256 public royaltyPercentage;
    uint256 public royaltyBase = 10000;

    // ------------------------ Core functions ------------------------ //

    // ADD address _payableToken
    // client and provider should both sign for a job
    function submitJob(address payable _client, address payable _provider, address _payableToken, uint256 _jobCost, string memory _jobURI) public payable noReentrant enabled {
        // Parameter validation
        require(address(msg.sender) == _client, "Only the client can call this function");
        // require(address(msg.sender).balance >= _jobCost, "Caller does not have enough funds to pay for the job");

        jobIdCount++;
        Job storage job = jobsList[jobIdCount];

        job.client = _client;
        job.payableToken = _payableToken;
        job.jobCost = _jobCost;
        job.jobURI = _jobURI;
        job.status = JobStatus.OPEN;

        // Validates the client and provider addresses
        clientAddresses[_client] = true;

        // Receive deposit amount
        IERC20(_payableToken).transferFrom(msg.sender, address(this), _jobCost);
        emit Received(_payableToken, _jobCost);

        // We emit the event of job creation so that the Graph protocol can be used to index the job
        emit jobCreated(jobIdCount, _client, _payableToken, _jobCost, _jobURI, job.status);
    }

    // function sendViaCall(address payable _to, uint256 amount) public payable {
    //     (bool sent, bytes memory data) = _to.call{value: amount}("");
    //     require(sent, "Failed to send Ether");
    // }

    function acceptJob(uint256 _jobId) public isValidJob(_jobId) enabled {
        require(providerAddresses[msg.sender], "Only validated providers can accept jobs");

        Job memory job = jobsList[_jobId];
        job.provider = payable(msg.sender);
        jobsList[_jobId].status = JobStatus.ACTIVE;

        // We emit the event of job creation so that the Graph protocol can be used to index the job
        emit jobActive(_jobId, job.client, job.provider, job.jobCost, job.jobURI, job.status);
    }

    // Only callable by client for jobs that haven't been accepted
    function cancelJob(uint256 _jobId) private isValidJob(_jobId) isOpenJob(_jobId) isClient(_jobId) enabled {
        Job memory job = jobsList[_jobId];
        jobsList[_jobId].status = JobStatus.CANCELLED;

        // We emit the event of job cancellation so that the Graph protocol can be updated
        emit jobCancelled(_jobId, job.client, job.provider, job.jobCost, job.jobURI, job.status);
    }

    // Only callable by provider
    function closeJob(uint256 _jobId) private isValidJob(_jobId) isActiveJob(_jobId) isProvider(_jobId) enabled {
        Job memory job = jobsList[_jobId];
        job.status = JobStatus.CLOSED;

        // We emit the event of job closing so that the Graph protocol can be updated
        emit jobClosed(_jobId, job.client, job.provider, job.jobCost, job.jobURI, job.status, job.openLabNFTURI);
    }

    function swap(uint256 jobId, string memory tokenURI) external payable isValidJob(jobId) isActiveJob(jobId) noReentrant enabled {
        Job memory job = jobsList[jobId];

        address client = jobsList[jobId].client;
        address provider = jobsList[jobId].provider;

        // Percentage sent to provider
        uint256 providerRevenue = jobsList[jobId].jobCost * (royaltyPercentage - royaltyPercentage) / royaltyBase;
        // Percentage sent to LabDAO
        uint256 marketRevenue = jobsList[jobId].jobCost * (royaltyPercentage / royaltyBase);

        // Send NFT to client
        IOpenLabNFT(openLabNFTAddress).safeMint(job.client, tokenURI);
        job.openLabNFTURI = tokenURI;

        // Send funds to provider and LabDAO
        IERC20(job.payableToken).transferFrom(address(this), job.provider, providerRevenue);
        IERC20(job.payableToken).transferFrom(address(this), payable(factoryAddress.owner()), marketRevenue);

        // Close job
        closeJob(jobId);
    }

    function returnFunds(uint256 jobId) private payable isValidJob(jobId) isOpenJob(jobId) noReentrant enabled {
        Job memory job = jobsList[jobId];

        // Refund 98% of deposit to prevent spamming of job creations
        uint256 refundAmount = job.jobCost * 98 / 100;
        // Send remaining 2% to LabDAO
        uint256 heldAmount = job.jobCost - refundAmount;

        IERC20(job.payableToken).transferFrom(address(this), job.client, refundAmount);
        IERC20(job.payableToken).transferFrom(address(this), payable(factoryAddress.owner()), heldAmount);
        cancelJob(jobId);
    }


    // ------------------------ Administrative functions ------------------------ //

    function addValidatedProvider(address _provider) public enabled {
        require(msg.sender == address(factoryAddress.owner()), "Only the factory owner can add validated providers");
        providerAddresses[_provider] = true;
    }

    function disableExchange() enabled external {
        require(msg.sender == address(factoryAddress.owner()), "Only the factory owner can disable the exchange");
        isEnabled = false;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // ------------------------ Function modifiers ------------------------ //

    modifier isValidJob(uint256 _jobId) {
        require(jobIdCount > 0 && _jobId > 0 && _jobId <= jobIdCount, "Job ID is not valid");
        _;
    }

    modifier isOpenJob(uint256 _jobId) {
        require(jobsList[_jobId].status == JobStatus.OPEN, "Job is not open");
        _;
    }

    modifier isActiveJob(uint256 _jobId) {
        require(jobsList[_jobId].status == JobStatus.OPEN, "Job is not active");
        _;
    }

    modifier isClient(uint256 _jobId) {
        require(jobsList[_jobId].client == msg.sender, "Only the client can call this function");
        _;
    }

    modifier isProvider(uint256 _jobId) {
        require(jobsList[_jobId].provider == msg.sender, "Only the provider can call this function");
        _;
    }

    modifier isValidClient(address _client) {
        require(clientAddresses[_client], "Client address not valid");
        _;
    }

    modifier isValidProvider(address _provider) {
        require(providerAddresses[_provider], "Provider address not valid");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyFactory() {
        require(address(msg.sender) == factoryAddress, "Only the factory can call this function");
        _;
    }

    modifier enabled() {
        require(isEnabled, "Exchange is not enabled");
        _;
    }
}
