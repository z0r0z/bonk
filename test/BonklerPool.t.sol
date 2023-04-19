// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {BonklerPool} from "src/BonklerPool.sol";
import {ERC721} from "lib/solmate/src/tokens/ERC721.sol";
import {Operation, Call, Signature, Keep} from "lib/keep/src/Keep.sol";
import {ProposalType, Kali} from "lib/keep/src/extensions/dao/Kali.sol";

contract BonklerPoolTest is Test, Keep(Keep(address(0))) {
    using stdStorage for StdStorage;

    BonklerPool internal constant POOL = BonklerPool(payable(0x7bb6aaa1546305fce78666d5cdA44207FACf9d47));
    ERC721 internal constant NFT = ERC721(0xABFaE8A54e6817F57F9De7796044E9a60e61ad67);
    Keep internal constant VAULT = Keep(0x70c0FB29FDEa65c274c574084123ff8DeE63d49f);
    Kali internal constant DAO = Kali(0x0ace16a3B30680d83E998224d6DA13aCb24abF3E);

    // Players/DAO.
    address internal constant alice = address(0xdead);
    address internal constant bob = address(0xdeaf);
    address internal constant chuck = address(0xbeef);

    // Ops.
    address internal constant ross = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
    address internal constant cattin = 0xC316f415096223561e2077c30A26043499d579aD;

    // Misc.
    Call[] calls;

    function setUp() public payable {
        // Create Ethereum fork.
        vm.createSelectFork(vm.rpcUrl("mainnet"));

        // Seed players' ETH.
        (bool success,) = alice.call{value: 10 ether}("");
        assert(success);
        (success,) = bob.call{value: 10 ether}("");
        assert(success);
        (success,) = chuck.call{value: 22 ether}("");
        assert(success);

        // Establish DAO control of VAULT.
        vm.prank(address(VAULT));
        VAULT.mint(address(DAO), CORE_KEY, 1, "");
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // or at https://github.com/foundry-rs/forge-std

    function testPoolBonkler() public payable {
        // Pool 42 ETH from players.
        vm.prank(alice);
        POOL.pool{value: 10 ether}();
        vm.prank(bob);
        POOL.pool{value: 10 ether}();
        vm.prank(chuck);
        POOL.pool{value: 22 ether}();

        // Confirm 42 VAULT/DAO shares are minted.
        assertEq(VAULT.balanceOf(alice, 0), 10 ether);
        assertEq(VAULT.balanceOf(bob, 0), 10 ether);
        assertEq(VAULT.balanceOf(chuck, 0), 22 ether);
        // ... and total supply = 42.
        assertEq(VAULT.totalSupply(0), 42 ether);
        // ... and that there is 42 ETH in POOL.
        assertEq(address(POOL).balance, 42 ether);
    }

    function testBidBonkler() public payable {
        // Pool 42 ETH from players.
        vm.prank(alice);
        POOL.pool{value: 10 ether}();
        vm.prank(bob);
        POOL.pool{value: 10 ether}();
        vm.prank(chuck);
        POOL.pool{value: 22 ether}();

        // Bump up time.
        vm.warp(block.timestamp + 999);

        // ~ Make bid via VAULT/DAO execution ~ //

        // Prep calldata.
        bytes memory tx_data = abi.encodeCall(POOL.bid, (4, 4411290049234895, 42 ether));

        // Pack call for VAULT.
        Call memory call0;
        call0.op = Operation.call;
        call0.to = address(POOL);
        call0.value = 0;
        call0.data = tx_data;

        // Pack call for DAO.
        tx_data = abi.encodeCall(VAULT.relay, (call0));

        Call[] memory call1 = new Call[](1);
        call1[0].op = Operation.call;
        call1[0].to = address(VAULT);
        call1[0].value = 0;
        call1[0].data = tx_data;

        // Make proposal by alice.
        vm.prank(address(alice));
        DAO.propose(call1, ProposalType.CALL, "Bid Bonkler 4");

        // Bump up time.
        vm.warp(block.timestamp + 69);

        // Alice and bob vote, meeting quorum (20%) so fast processing.
        vm.prank(address(alice));
        DAO.vote(1, true, "yep");
        vm.prank(address(bob));
        DAO.vote(1, true, "yep");

        // Bid 42 ETH on Bonkler 4.
        DAO.processProposal(1, call1, ProposalType.CALL, "Bid Bonkler 4");
    }
}
