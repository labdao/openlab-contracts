# OpenLab Smart Contracts

**Note:** WIP.

Deployed contracts on Rinkeby Testnet (as of 04 Mar 2022)
* [Exchange.sol](https://rinkeby.etherscan.io/address/0x55b63e51cedeb16c777f984812d8653e4b9b803e#code)
* [OpenLabNFT.sol](https://rinkeby.etherscan.io/address/0xd301acda1075a59aba9c4c536695b054ccb0754a) -- this contract's source code has not been "verified" by Etherscan. To see the source code, view the [IPFS publication](https://ipfs.io/ipfs/QmNSG2xbSBVu2sydKXN731KQr5AqTijpfiF3nxhKumjR91) (use Brave browser).

## Contract Descriptions

### Exchange.sol

The OpenLab exchange is the core of where Web3 transactions will be managed. Each Job has a **client, provider, job cost, job URI (job metadata on IPFS) and status**.

Jobs can be created, closed, and cancelled on the Exchange. 

### Escrow.sol

When a job is created, the job funds are temporarily stored in the Escrow contract. 

### OpenLabNFT.sol

The OpenLabNFT contract is our ERC721 token which gets transferred upon completion of a job. Checks that both the provider and client are validated addresses per Exchange.sol, and mints an OpenLab NFT (OLNFT).

## Setup

TO DO: add the Hardhat-specific instructions.

## In Progress

* Implement ExchangeFactory pattern so LabDAO multisig can initialize and own the factory contract
* Finish Escrow payable functionality
* Job type toggling
* Payable token toggling
* Add test files to Hardhat
* Polygon testnet deployment (target by Apr 1)
* Polygon mainnet deployment (target by Apr 11)