// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;
    bytes paymasterAndData;
    bytes signature;
}
*/

//Populate PackedUserOperation : data and signature
contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function run() public {
        address tokenReceiver = 0x2690b40cFBef1A15EF3c33805bd5b1CC00E6f7f5; //my receiver wallet
        //address minimalAccountAddress = 0x74F4861568356A377c08A71e5c02E78a60d2a51D; //MinimalAccount address
        address minimalAccountAddress = DevOpsTools.get_most_recent_deployment(
            "MinimalAccount",
            block.chainid
        );

        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address dest = config.tokenAddress; //  chainlink token
        uint256 value = 0;

        // Add your call data here(functionData)
        bytes memory functionData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            tokenReceiver,
            777e13
        );
        bytes memory executeCalldata = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            address(dest), // target address
            value, // value
            functionData // data
        );
        PackedUserOperation memory userOp = generateSignedUserOperation(
            executeCalldata,
            config,
            address(minimalAccountAddress)
        );
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        vm.startBroadcast(config.account);
        IEntryPoint(config.entryPoint).handleOps(
            userOps,
            payable(config.account)
        );
        vm.stopBroadcast();
    }

    //Generate a signed PackedUserOperation for entry point contract
    function generateSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
    ) public view returns (PackedUserOperation memory) {
        //Get Unsigned data
        //uint256 nonce = vm.getNonce(minimalAccount) - 1;
        uint256 nonce = IEntryPoint(config.entryPoint).getNonce(
            minimalAccount,
            0
        );

        //uint256 nonce = 4;
        console2.log("Nonce :", nonce);

        PackedUserOperation memory userOp = _generateUnsignedUserOperation(
            callData,
            minimalAccount,
            nonce,
            config.payMaster
        );

        //Get the userOpHas
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(
            userOp
        ); //keccak256(abi.encode(userOp.hash(), address(this), block.chainid));
        // bytes32 userOpHash = keccak256(
        //     abi.encode(
        //         userOp,
        //         address(config.entryPoint),
        //         block.chainid // to prevent replay attack on different chains
        //     )
        // );

        bytes32 digest = userOpHash.toEthSignedMessageHash();
        //The digest is calculated by prefixing a bytes32 `messageHash` with
        //* `"\x19Ethereum Signed Message:\n32"` and hashing the result.

        //Sign the digest
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            //for test
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
            console2.log("Using ANVIL_DEFAULT_KEY to sign the user operation");
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v); // Note the order
        return userOp;
    }

    function _generateUnsignedUserOperation(
        bytes memory callData,
        address sender,
        uint256 nonce,
        address payMaster
    ) internal pure returns (PackedUserOperation memory) {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        address paymaster = payMaster;
        uint128 validationGasLimit = 1000000;
        uint128 postOpGasLimit = 1000000;
        bytes memory paymasterSpecificData = hex"";

        bytes memory paymasterAndData = abi.encodePacked(
            address(paymaster), // 20 bytes
            uint128(validationGasLimit), // 16 bytes
            uint128(postOpGasLimit), // 16 bytes
            bytes(paymasterSpecificData) // optional, variable length
        );

        return
            PackedUserOperation({
                sender: sender,
                nonce: nonce,
                initCode: hex"",
                callData: callData,
                accountGasLimits: bytes32(
                    (uint256(verificationGasLimit) << 128) | callGasLimit
                ),
                preVerificationGas: verificationGasLimit,
                gasFees: bytes32(
                    (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
                ),
                paymasterAndData: paymasterAndData,
                signature: hex""
            });
    }
}
