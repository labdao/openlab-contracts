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

When a job is created, the job funds are temporarily stored in the Escrow contract. The Escrow contract received Ether when a new job is created on the Exchange. When a provider completes a job, the swap function gets called which triggers a) Minting of an OpenLab NFT and transferring it to the client, b) Sending the deposited job funds to the provider, and c) Setting the job status to closed.

### OpenLabNFT.sol

The OpenLabNFT contract is our ERC721 token which gets transferred upon completion of a job. Checks that both the provider and client are validated addresses per Exchange.sol, and mints an OpenLab NFT (OLNFT).

## Setup

TO DO: add the Hardhat-specific instructions.

## In Progress

* Implement ExchangeFactory pattern so LabDAO multisig can initialize and own the factory contract
* Payable token toggling
* Add test files to Hardhat
* Polygon testnet deployment (target by Apr 1)
* Polygon mainnet deployment (target by Apr 11)