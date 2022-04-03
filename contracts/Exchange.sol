// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OpenLabNFT.sol";

contract Exchange {

    // ---------------------------- Constructor ---------------------------------// 

    constructor(address _factoryAddress, address _factoryOwner, address _openLabNFTAddress, uint256 _royaltyPercentage) {
        isEnabled = true;
        factoryAddress = _factoryAddress;
        factoryOwner = _factoryOwner;
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
    address public factoryOwner;

    // Values set by owner of ExchangeFactory
    address public openLabNFTAddress;
    uint256 public royaltyPercentage;
    // Royalty base is 100% x 100 for decimal percentages
    uint256 public royaltyBase = 10000;

    // ------------------------ Core functions ------------------------ //

    // ADD address _payableToken
    // client and provider should both sign for a job
    function submitJob(address payable _client, address _payableToken, uint256 _jobCost, string memory _jobURI) public payable noReentrant enabled {
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
        address client = job.client;
        address provider = job.provider;
        address payableToken = job.payableToken;

        // Percentage sent to provider
        uint256 providerRevenue = job.jobCost * (royaltyPercentage - royaltyPercentage) / royaltyBase;
        // Percentage sent to LabDAO
        uint256 marketRevenue = job.jobCost * (royaltyPercentage / royaltyBase);

        // Send NFT to client
        IOpenLabNFT(openLabNFTAddress).safeMint(client, tokenURI);
        job.openLabNFTURI = tokenURI;

        // Send funds to provider and LabDAO
        IERC20(payableToken).transferFrom(address(this), provider, providerRevenue);
        IERC20(payableToken).transferFrom(address(this), payable(factoryOwner), marketRevenue);

        // Close job
        closeJob(jobId);
    }

    function returnFunds(uint256 jobId) external payable isValidJob(jobId) isOpenJob(jobId) isClient(jobId) noReentrant enabled {
        Job memory job = jobsList[jobId];

        // Refund 98% of deposit to prevent spamming of job creations
        uint256 refundAmount = job.jobCost * 98 / 100;
        // Send remaining 2% to LabDAO
        uint256 heldAmount = job.jobCost - refundAmount;

        IERC20(job.payableToken).transferFrom(address(this), job.client, refundAmount);
        IERC20(job.payableToken).transferFrom(address(this), payable(factoryOwner), heldAmount);
        cancelJob(jobId);
    }

    // ------------------------ Administrative functions ------------------------ //

    function setRoyaltyPercentage(uint256 _percentage) public enabled {
        require(msg.sender == address(factoryOwner), "Only the factory owner can update the royalty percentage");
        royaltyPercentage = _percentage;
    }

    function addValidatedProvider(address _provider) public enabled {
        require(msg.sender == address(factoryOwner), "Only the factory owner can add validated providers");
        providerAddresses[_provider] = true;
    }

    function disableExchange() enabled external {
        require(msg.sender == address(factoryOwner), "Only the factory owner can disable the exchange");
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
