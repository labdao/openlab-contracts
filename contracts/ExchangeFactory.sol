pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Exchange.sol";

contract ExchangeFactory is Ownable {

    uint256 disabledCount;

    mapping (address => bool) public exchangeEnabled;

    event ExchangeCreated(address exchangeAddress);

    // Royalty percentage should be percentage number x 100
    function createExchange(address openLabNFTContract, uint256 royaltyPercentage) external {
        // Points to the OpenLabNFT contract that this Exchange instance should use
        Exchange exchange = new Exchange(address(this), owner(), openLabNFTContract, royaltyPercentage);
        exchangeEnabled[exchange.address] = true;
        emit ExchangeCreated(address(exchange));
    }

    function disable(address _exchange) external onlyOwner {
        require(!exchangeEnabled[_exchange]);
        exchangeEnabled[_exchange.address] = false;
        disabledCount++;
    }
}

interface IExchangeFactory {
    function disable() external {}
}