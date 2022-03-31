pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Exchange.sol";

contract ExchangeFactory is Ownable {
    Exchange[] public exchanges;

    uint disabledCount;

    event ExchangeCreated(address exchangeAddress);

    function createExchange(address openLabNFTContract, uint royaltyPercentage) external {
        // Points to the OpenLabNFT contract that this Exchange instance should use
        Exchange exchange = new Exchange(openLabNFTContract);
        exchanges.push(exchange);
        emit ExchangeCreated(address(exchange));
    }

    function getExchanges() external view returns(Exchange[] memory _exchanges) {
        _exchanges = new Exchange[](exchanges.length - disabledCount);
        uint count;
        for (uint i = 0; i < exchanges.length; i++) {
            if (exchanges[i].isEnabled()) {
                _exchanges[count] = exchanges[i];
                count++;
            }
        }
    }

    function disable(Exchange exchange) external onlyOwner {
        exchanges[exchange.exchangeIndex].disableExchange();
        disabledCount++;
    }

    function setRoyaltyPercentage(Exchange exchange, uint _royaltyPercentage) public onlyOwner {
        exchanges[exchange.index()].royalty = _royaltyPercentage;
    }
}