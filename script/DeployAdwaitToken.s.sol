// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/AdwaitToken.sol";

contract DeployAdwaitToken is Script {
    function run() external returns (AdwaitToken) {
        // Configuration - adjust these values as needed
        string memory tokenName = "AdwaitToken";
        string memory tokenSymbol = "ADW";
        uint256 initialSupply = 1000000 * 10**18; // 1 million tokens with 18 decimals
        
        // Start broadcasting transactions
        vm.startBroadcast();
        
        // Deploy the token contract
        AdwaitToken token = new AdwaitToken(
            tokenName,
            tokenSymbol,
            initialSupply
        );
        
        console.log("AdwaitToken deployed at:", address(token));
        console.log("Token Name:", tokenName);
        console.log("Token Symbol:", tokenSymbol);
        console.log("Initial Supply:", initialSupply);
        console.log("Deployer (Admin + Minter + Owner):", msg.sender);
        console.log("Contract is NOT paused by default");
        
        vm.stopBroadcast();
        
        return token;
    }
}
