// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {DeployMinimal} from "script/DeployMinimal.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SendPackedUserOp} from "script/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;
    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock erc20Mock;
    SendPackedUserOp sendPackedUserOp;

    uint256 constant AMOUNT = 1e18;

    address randomuser = makeAddr("randomUser");

    function setUp() external {
        DeployMinimal deployer = new DeployMinimal();
        (helperConfig, minimalAccount) = deployer.deployMinimalAccount();
        erc20Mock = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    function testUserCanDirectlyExecute() public {
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(
            address(erc20Mock),
            0,
            abi.encodeWithSignature(
                "mint(address,uint256)",
                address(this),
                AMOUNT
            )
        );
        assertEq(erc20Mock.balanceOf(address(this)), AMOUNT);
    }

    function testNotUserCanNotExecute() public {
        // vm.prank(minimalAccount.owner()); // owner is
        vm.expectRevert(
            MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector
        );
        minimalAccount.execute(
            address(erc20Mock),
            0,
            abi.encodeWithSignature(
                "mint(address,uint256)",
                address(this),
                AMOUNT
            )
        );
    }

    function testRecoverSignerOp() public {
        address dest = address(erc20Mock);
        uint256 value = 0;
        //calldata sent by execute()
        bytes memory functionData = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            AMOUNT
        );

        //calldata packed by user , used for userOp.callData
        bytes memory executeCalldata = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );

        //calldata sent by user , to entry point
        PackedUserOperation memory userOp = sendPackedUserOp
            .generateSignedUserOperation(
                executeCalldata,
                helperConfig.getConfig(),
                address(minimalAccount)
            );

        bytes32 userOperationHash = IEntryPoint(
            helperConfig.getConfig().entryPoint
        ).getUserOpHash(userOp);
        address actualSigner = ECDSA.recover(
            userOperationHash.toEthSignedMessageHash(),
            userOp.signature
        );

        assertEq(actualSigner, minimalAccount.owner(), "Signer mismatch");
    }

    function testValidationOfUserOps() public {
        address dest = address(erc20Mock);
        uint256 value = 0;
        //calldata sent by execute()
        bytes memory functionData = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            AMOUNT
        );

        //calldata packed by user , used for userOp.callData
        bytes memory executeCalldata = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );

        //calldata sent by user , to entry point
        PackedUserOperation memory userOp = sendPackedUserOp
            .generateSignedUserOperation(
                executeCalldata,
                helperConfig.getConfig(),
                address(minimalAccount)
            );

        bytes32 userOperationHash = IEntryPoint(
            helperConfig.getConfig().entryPoint
        ).getUserOpHash(userOp);
        uint256 missingAccountFunds = 1e18;

        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(
            userOp,
            userOperationHash,
            missingAccountFunds
        );
        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteCommands() public {
        address dest = address(erc20Mock);
        uint256 value = 0;
        //calldata sent by execute()
        bytes memory functionData = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            AMOUNT
        );

        //calldata packed by user , used for userOp.callData
        bytes memory executeCalldata = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );

        //calldata sent by user , to entry point
        PackedUserOperation memory userOp = sendPackedUserOp
            .generateSignedUserOperation(
                executeCalldata,
                helperConfig.getConfig(),
                address(minimalAccount)
            );

        vm.deal(address(minimalAccount), 1e18);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        vm.prank(randomuser);
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(
            userOps,
            payable(address(12345))
        );

        assertEq(erc20Mock.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
