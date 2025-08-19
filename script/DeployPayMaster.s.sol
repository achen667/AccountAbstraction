// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {PayMaster} from "src/ethereum/PayMaster.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployPayMaster is Script {
    function run() public {
        deployPayMaster();
    }

    function deployPayMaster() public returns (HelperConfig, PayMaster) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        PayMaster payMaster = new PayMaster(config.entryPoint);
        //only needed when msg.sender and onwer are different
        payMaster.transferOwnership(config.account);
        vm.stopBroadcast();
        return (helperConfig, payMaster);
    }
}
