// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import {IAccount, ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
// import {Transaction, MemoryTransactionHelper} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
// import {SystemContractsCaller} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
// import {NONCE_HOLDER_SYSTEM_CONTRACT, BOOTLOADER_FORMAL_ADDRESS, DEPLOYER_SYSTEM_CONTRACT} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
// import {INonceHolder} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";

// import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
// import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
// import {Utils} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/Utils.sol";

// //import {MessageHashUtils} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MessageHashUtils.sol";

// contract ZkMinimalAccount is IAccount, Ownable {
//     using MemoryTransactionHelper for Transaction;

//     error ZkMinimalAccount__NotEnoughBalance(uint256 required, uint256 actual);
//     error ZkMinimalAccount__NotFromBootLoader();
//     error ZkMinimalAccount__InvalidSignature();
//     error ZkMinimalAccount__ExecutionFailed();
//     error ZkMinimalAccount__NotFromBootLoaderOrOwner();
//     error ZkMinimalAccount__FailedToPay();

//     modifier requireFromBootLoader() {
//         if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
//             revert ZkMinimalAccount__NotFromBootLoader();
//         }
//         _;
//     }

//     modifier requireFromBootLoaderOrOwner() {
//         if (msg.sender != BOOTLOADER_FORMAL_ADDRESS && msg.sender != owner()) {
//             revert ZkMinimalAccount__NotFromBootLoaderOrOwner();
//         }
//         _;
//     }

//     constructor() Ownable(msg.sender) {}

//     /*//////////////////////////////////////////////////////////////
//                            EXTERNAL FUNCTION
//     //////////////////////////////////////////////////////////////*/

//     function validateTransaction(
//         bytes32 /*_txHash*/,
//         bytes32 /*_suggestedSignedHash*/,
//         Transaction memory _transaction
//     ) external payable requireFromBootLoader returns (bytes4 magic) {
//         return _validateTransaction(_transaction);
//     }

//     function executeTransaction(
//         bytes32 /*_txHash*/,
//         bytes32 /*_suggestedSignedHash*/,
//         Transaction memory _transaction
//     ) external payable requireFromBootLoaderOrOwner {
//         _exectuteTransaction(_transaction);
//     }

//     // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
//     // since it typically should not be trusted.
//     function executeTransactionFromOutside(
//         Transaction memory _transaction
//     ) external payable {
//         bytes4 success = _validateTransaction(_transaction);
//         if (success != ACCOUNT_VALIDATION_SUCCESS_MAGIC) {
//             revert ZkMinimalAccount__InvalidSignature();
//         }
//         _exectuteTransaction(_transaction);
//     }

//     function payForTransaction(
//         bytes32,
//         /*_txHash*/ bytes32,
//         /*_suggestedSignedHash*/ Transaction memory _transaction
//     ) external payable {
//         bool success = _transaction.payToTheBootloader();
//         if (!success) {
//             revert ZkMinimalAccount__FailedToPay();
//         }
//     }

//     function prepareForPaymaster(
//         bytes32 _txHash,
//         bytes32 _possibleSignedHash,
//         Transaction memory _transaction
//     ) external payable {}

//     /*//////////////////////////////////////////////////////////////
//                            INTERNAL FUNCTION
//     //////////////////////////////////////////////////////////////*/
//     receive() external payable {}

//     /*//////////////////////////////////////////////////////////////
//                            INTERNAL FUNCTION
//     //////////////////////////////////////////////////////////////*/
//     function _validateTransaction(
//         Transaction memory _transaction
//     ) internal returns (bytes4 magic) {
//         SystemContractsCaller.systemCallWithPropagatedRevert(
//             uint32(gasleft()),
//             address(NONCE_HOLDER_SYSTEM_CONTRACT),
//             0,
//             abi.encodeCall(
//                 INonceHolder.incrementMinNonceIfEquals,
//                 (_transaction.nonce)
//             )
//         );

//         //Check if the account has enough balance to cover the transaction
//         uint256 totalRequiredBalance = _transaction.totalRequiredBalance(); //MemoryTransactionHelper.totalRequiredBalance(_transaction);
//         if (totalRequiredBalance > address(this).balance) {
//             revert ZkMinimalAccount__NotEnoughBalance(
//                 totalRequiredBalance,
//                 address(this).balance
//             );
//         }

//         //Verify the transaction signature
//         bytes32 txHash = _transaction.encodeHash();
//         address singer = ECDSA.recover(txHash, _transaction.signature);
//         if (singer == owner()) {
//             magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
//         } else {
//             magic = bytes4(0);
//             // If the signature is not from the owner, we do not allow the transaction to proceed.
//             // This is a minimal account implementation, so we do not support other signers.
//             // In a more complex implementation, you might want to handle different signers or signatures.
//         }
//     }

//     function _exectuteTransaction(Transaction memory _transaction) internal {
//         address to = address(uint160(_transaction.to));
//         uint128 value = Utils.safeCastToU128(_transaction.value);
//         bytes memory data = _transaction.data;

//         if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
//             uint32 gas = Utils.safeCastToU32(gasleft());
//             SystemContractsCaller.systemCallWithPropagatedRevert(
//                 gas,
//                 to,
//                 value,
//                 data
//             );
//         } else {
//             bool success;
//             assembly {
//                 success := call(
//                     gas(),
//                     to,
//                     value,
//                     add(data, 0x20),
//                     mload(data),
//                     0,
//                     0
//                 )
//             }
//             if (!success) {
//                 revert ZkMinimalAccount__ExecutionFailed();
//             }
//         }
//     }
// }
