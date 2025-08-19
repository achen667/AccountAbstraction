 #  Abstract Account (ERC-4337 Minimal Account)

This project implements a **Minimal Smart Account** using [ERC-4337 Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337).  
It includes deployment scripts, helper utilities, and example flows for sending **UserOperations** through an [EntryPoint](https://github.com/eth-infinitism/account-abstraction). 
##  Features

-   **MinimalAccount.sol** – a lightweight ERC-4337 account with:
    
    -   ECDSA signature validation
        
    -   `execute()` to forward calls
        
    -   Prefund support for gas
        
-   **SendPackedUserOp.s.sol** – script to construct, sign, and send a `PackedUserOperation` via EntryPoint.
    
     
##   Installation

```sh
git clone https://github.com/achen667/AccountAbstraction.git
cd AccountAbstruction
make install

```

Dependencies installed:

-   [forge-std](https://github.com/foundry-rs/forge-std)
    
-   [openzeppelin-contracts v5](https://github.com/OpenZeppelin/openzeppelin-contracts)
    
-   [eth-infinitism/account-abstraction](https://github.com/eth-infinitism/account-abstraction)
    
-   [cyfrin/foundry-era-contracts](https://github.com/cyfrin/foundry-era-contracts)
    
-   [cyfrin/foundry-devops](https://github.com/cyfrin/foundry-devops)
    

 

##  Build & Test

Build contracts:

```sh
make build

```

Run tests:

```sh
make test

```

Forked mainnet testing:

```sh
make testFork

```

Snapshot gas costs:

```sh
make snapshot

```

 

##  Deployment

### Deploy Minimal Account

Example: deploy to Arbitrum Sepolia

```sh
make deployEth

```

### Send UserOperation

```sh
make sendUserOp

```

### Verify contract

```sh
make verify

```

 

##  Development

Run a local Anvil chain:

```sh
make anvil

```

Get EntryPoint contract locally:

```sh
make getEntryPoint

```

Flatten contract for verification:

```sh
make flatten

```

 
##  zkSync Support

Build for zkSync:

```sh
make zkbuild

```

Run tests on zkSync:

```sh
make zktest

```

Deploy to zkSync:

```sh
make zkdeploy

``` 

##  Project Structure

```
src/
  ethereum/
    MinimalAccount.sol     # ERC-4337 Smart Account
  zkSync/
    ZkMinimalAccount.sol   # zkSync version
script/
  DeployMinimal.s.sol      # Deployment script
  SendPackedUserOp.s.sol   # Example UserOperation sender
  HelperConfig.s.sol       # Config loader

```

 

##  MinimalAccount.sol (ERC-4337 Smart Account)

-   **Owner** can control the account.
    
-   **EntryPoint** enforces validation via `validateUserOp`.
    
-   Signature validation uses `ECDSA.recover`.
    
-   Supports prefund to cover gas.
    
-   Has a `receive()` to accept ETH.
    

 

##  Example Flow

1.  Deploy `MinimalAccount` via `make deployEth`.
    
2.  Encode calldata for a token approval:
    
    ```sh
    make getCalldata
    
    ```
    
3.  Construct and sign `PackedUserOperation` using `SendPackedUserOp.s.sol`.
    
4.  Relay it via EntryPoint → executes onchain.
    

  
 