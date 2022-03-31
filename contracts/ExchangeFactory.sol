pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Exchange.sol";

contract ExchangeFactory is Ownable {
    Exchange[] public exchanges;
    uint disabledCount;

    event ExchangeCreated(address exchangeAddress, uint data);

    function createExchange(uint data) external {
        Exchange exchange = new Exchange(data, exchanges.length);
        exchanges.push(exchange);
        emit ExchangeCreated(address(exchange), data);
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

    function setEscrowAddress(Exchange exchange, address payable _address) public onlyOwner {
        exchanges[exchange.exchangeIndex].escrowAddress = _address;
    }



    function setRoyaltyPercentage(Exchange exchange, uint _royaltyPercentage) public onlyOwner {
        exchanges[exchange.index()].royalty = _royaltyPercentage;
    }
}