//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        //Before vm.startBroadcast it does not cost gas coz it is not a tx!
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); //do it like a tuple coz you have got a struct return!
        //activeNetworkConfig is of type NetworkConfig(a Struct that has an address as its key) but the above line still works!

        vm.startBroadcast();
        //it counts as a tx after this.
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
