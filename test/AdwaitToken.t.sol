// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/AdwaitToken.sol";

contract AdwaitTokenTest is Test {
    AdwaitToken public token;
    
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    
    uint256 constant INITIAL_SUPPLY = 1000000 * 10**18; // 1 million tokens
    
    event TokensMinted(address indexed minter, address indexed to, uint256 amount);
    event AdminPaused(address indexed admin);
    event AdminUnpaused(address indexed admin);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    
    function setUp() public {
        vm.prank(admin);
        token = new AdwaitToken("AdwaitToken", "ADW", INITIAL_SUPPLY);
    }
    
    // ============ Deployment Tests ============
    
    function test_Deployment() public view {
        assertEq(token.name(), "AdwaitToken");
        assertEq(token.symbol(), "ADW");
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY);
    }
    
    function test_AdminRoleAssignedToDeployer() public view {
        assertTrue(token.isAdmin(admin));
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
    }
    
    function test_MinterRoleAssignedToDeployer() public view {
        assertTrue(token.isMinter(admin));
        assertTrue(token.hasRole(token.MINTER_ROLE(), admin));
    }

    function test_OwnerSetToDeployer() public view {
        assertEq(token.owner(), admin);
    }
    
    // ============ Minting Tests ============
    
    function test_MinterCanMint() public {
        vm.prank(admin);
        token.grantMinterRole(minter);
        
        uint256 mintAmount = 1000 * 10**18;
        
        vm.prank(minter);
        token.mint(user1, mintAmount);
        
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }
    
    function test_AdminCanMint() public {
        uint256 mintAmount = 500 * 10**18;
        
        vm.prank(admin);
        token.mint(user1, mintAmount);
        
        assertEq(token.balanceOf(user1), mintAmount);
    }
    
    function test_RevertWhen_NonMinterTriesToMint() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, 100 * 10**18);
    }

    function test_RevertWhen_MintWhilePaused() public {
        vm.prank(admin);
        token.pause();
        
        vm.prank(admin);
        vm.expectRevert();
        token.mint(user1, 100 * 10**18);
    }
    
    // ============ Pause/Unpause Tests ============
    
    function test_AdminCanPause() public {
        vm.prank(admin);
        token.pause();
        
        assertTrue(token.paused());
    }
    
    function test_AdminCanUnpause() public {
        vm.prank(admin);
        token.pause();
        
        vm.prank(admin);
        token.unpause();
        
        assertFalse(token.paused());
    }
    
    function test_RevertWhen_NonAdminPauses() public {
        vm.prank(user1);
        vm.expectRevert();
        token.pause();
    }
    
    function test_RevertWhen_NonAdminUnpauses() public {
        vm.prank(admin);
        token.pause();
        
        vm.prank(user1);
        vm.expectRevert();
        token.unpause();
    }
    
    function test_RevertWhen_TransferWhilePaused() public {
        vm.prank(admin);
        token.pause();
        
        vm.prank(admin);
        vm.expectRevert();
        token.transfer(user1, 100 * 10**18);
    }
    
    // ============ Role Management Tests ============
    
    function test_AdminCanGrantMinterRole() public {
        assertFalse(token.isMinter(user1));
        
        vm.prank(admin);
        token.grantMinterRole(user1);
        
        assertTrue(token.isMinter(user1));
    }
    
    function test_AdminCanRevokeMinterRole() public {
        vm.prank(admin);
        token.grantMinterRole(minter);
        assertTrue(token.isMinter(minter));
        
        vm.prank(admin);
        token.revokeMinterRole(minter);
        
        assertFalse(token.isMinter(minter));
    }
    
    function test_RevertWhen_NonAdminGrantsMinterRole() public {
        vm.prank(user1);
        vm.expectRevert();
        token.grantMinterRole(user2);
    }
    
    function test_RevertWhen_NonAdminRevokesMinterRole() public {
        vm.prank(admin);
        token.grantMinterRole(minter);
        
        vm.prank(user1);
        vm.expectRevert();
        token.revokeMinterRole(minter);
    }
    
    // ============ Transfer Tests ============
    
    function test_UserCanTransferTokens() public {
        vm.prank(admin);
        token.mint(user1, 1000 * 10**18);
        
        uint256 transferAmount = 300 * 10**18;
        
        vm.prank(user1);
        token.transfer(user2, transferAmount);
        
        assertEq(token.balanceOf(user1), 700 * 10**18);
        assertEq(token.balanceOf(user2), 300 * 10**18);
    }
    
    function test_RevertWhen_TransferExceedsBalance() public {
        vm.prank(admin);
        token.mint(user1, 100 * 10**18);
        
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 200 * 10**18);
    }
    
    // ============ Multiple Minters Tests ============
    
    function test_MultipleMinters() public {
        vm.prank(admin);
        token.grantMinterRole(minter);
        
        vm.prank(admin);
        token.grantMinterRole(user1);
        
        assertTrue(token.isMinter(minter));
        assertTrue(token.isMinter(user1));
        
        vm.prank(minter);
        token.mint(user2, 100 * 10**18);
        
        vm.prank(user1);
        token.mint(user2, 200 * 10**18);
        
        assertEq(token.balanceOf(user2), 300 * 10**18);
    }
    
    // ============ Edge Cases ============
    
    function test_DeploymentWithZeroInitialSupply() public {
        vm.prank(admin);
        AdwaitToken newToken = new AdwaitToken("Test", "TST", 0);
        
        assertEq(newToken.totalSupply(), 0);
        assertEq(newToken.balanceOf(admin), 0);
        assertTrue(newToken.isAdmin(admin));
        assertTrue(newToken.isMinter(admin));
    }
    
    function test_RevokedMinterCannotMint() public {
        vm.prank(admin);
        token.grantMinterRole(minter);
        
        vm.prank(minter);
        token.mint(user1, 100 * 10**18);
        
        vm.prank(admin);
        token.revokeMinterRole(minter);
        
        vm.prank(minter);
        vm.expectRevert();
        token.mint(user1, 100 * 10**18);
    }

    function test_CanTransferAfterUnpause() public {
        // Pause
        vm.prank(admin);
        token.pause();
        
        // Try transfer (should fail)
        vm.prank(admin);
        vm.expectRevert();
        token.transfer(user1, 100 * 10**18);
        
        // Unpause
        vm.prank(admin);
        token.unpause();
        
        // Transfer should work now
        vm.prank(admin);
        token.transfer(user1, 100 * 10**18);
        
        assertEq(token.balanceOf(user1), 100 * 10**18);
    }
    
    function testFuzz_MintAmount(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint256).max / 2);
        
        vm.prank(admin);
        token.mint(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
    }
}
