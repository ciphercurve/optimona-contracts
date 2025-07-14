// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import {IndieTreat} from "../src/IndieTreat.sol";
import "forge-std/console.sol";

contract DeployIndieTreat is Script {
    IndieTreat public indieTreat;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the IndieTreat contract
        indieTreat = new IndieTreat();

        vm.stopBroadcast();

        // Log deployed contract address
        console.log("IndieTreat deployed to:", address(indieTreat));
    }
}
