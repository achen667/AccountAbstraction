// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {Script, console2} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
        address tokenAddress; // link token
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    address constant BURNER_WALLET = 0xA0fA8c7DB6eeF148A8413DAdA118202D9594D0fc;
    address constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        //networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZksyncSepoliaConfig();
        networkConfigs[ARBITRUM_SEPOLIA_CHAIN_ID] = getArbitrumSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getEthSepoliaConfig()
        internal
        pure
        returns (NetworkConfig memory config)
    {
        //config.entryPoint = 0x0576a174D229E3cFA37253523E645A78A0C91B57;
        //0x0000000071727De22E5E9d8BAf0edAc6f37da032
        config.entryPoint = address(0);
        config.account = BURNER_WALLET;
        config.tokenAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    }

    function getZksyncSepoliaConfig()
        internal
        pure
        returns (NetworkConfig memory config)
    {
        config.entryPoint = address(0);
        config.account = BURNER_WALLET;
    }

    function getArbitrumSepoliaConfig()
        internal
        pure
        returns (NetworkConfig memory config)
    {
        config.entryPoint = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
        config.account = BURNER_WALLET;
        config.tokenAddress = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            console2.log("localNetworkConfig already exists");
            return localNetworkConfig;
        }

        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entryPoint: address(entryPoint),
            account: ANVIL_DEFAULT_ACCOUNT,
            tokenAddress: address(0)
        });
        return localNetworkConfig;
    }
}
