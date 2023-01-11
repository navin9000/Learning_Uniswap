//SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.7;

///import
import "../multiSig.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

contract multiSigTest is Test {
    MultiSig mult;

    ///@dev setup runs before every test runs
    function setUp() public {
        address[] memory arr = new address[](5);
        arr[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        arr[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        arr[2] = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        arr[3] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        arr[4] = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;
        mult = new MultiSig(arr, 5);
        emit log_address(address(mult));
        // this is one way to fund
        // vm.deal(address(mult), 10 ether);

        vm.deal(address(this), 10 ether);
        (bool success, ) = address(mult).call{value: 10 ether}(
            abi.encodeWithSignature("depositeFunds()")
        );
        require(success, "value transffered failed");
    }

    ///@dev checking the attack contract balance
    function testCheckbalance() public {
        assertEq(mult.getBalance(), 10 ether);
    }

    ///@dev is owner or not with invalid address
    function test_IsOwner() public {
        address[] memory arr = new address[](5);
        arr[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        arr[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        arr[2] = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        arr[3] = vm.addr(2);
        arr[4] = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

        uint256 count = mult.noOfConfirmations();
        for (uint256 i; i < count; i++) {
            assertTrue(mult.isOwner(arr[i]));
        }
    }

    ///@dev is owner or not
    function test_IsOwner2() public {
        address[] memory arr = new address[](5);
        arr[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        arr[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        arr[2] = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        arr[3] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        arr[4] = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

        uint256 count = mult.noOfConfirmations();
        for (uint256 i; i < count; i++) {
            assertTrue(mult.isOwner(arr[i]));
        }
    }

    ///@dev proposalTransaction
    function test_ProposalTransaction() public {
        address to = vm.addr(1);
        //ox5b....c4 to msg.sender
        vm.prank(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        //called proposaltransaction
        mult.proposalTransaction(to, 3 ether);
        //checking for ownerProposalIndex
        assertEq(
            mult.ownerProposalIndex(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4),
            0
        );
    }

    ///@dev proposalTransaction other than owners
    function test_ProposalTransaction2() public {
        address to = vm.addr(1);
        address caller = vm.addr(2);
        //caller to msg.sender
        vm.prank(caller);
        //called proposaltransaction
        mult.proposalTransaction(to, 3 ether);
        //checking for ownerProposalIndex
        assertEq(
            mult.ownerProposalIndex(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4),
            0
        );
    }

    ///@dev confirmProposalTransaction with other owners
    function test_confirmProposalTransaction() public {
        address[] memory arr = new address[](5);
        arr[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        arr[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        arr[2] = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        arr[3] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        arr[4] = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

        address to = vm.addr(1);
        //ox5b....c4 to msg.sender
        vm.prank(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        //called proposaltransaction
        mult.proposalTransaction(to, 3 ether);
        uint256 count = mult.noOfConfirmations();
        for (uint256 i; i < count; i++) {
            if (arr[i] == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4) {
                continue;
            }
            vm.prank(arr[i]);
            mult.confirmProposalTransaction(
                0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
            );
        }
        (address two, uint256 value, bool approve, uint256 confirmations) = mult
            .transactions(0);

        assertGe(confirmations, 3);
        assertEq(confirmations, 4);
    }

    ///@dev revokeProposalTransaction by the propsal owner
    function test_RevokeProposaltransaction() public {
        address to = vm.addr(1);
        //ox5b....c4 to msg.sender
        vm.prank(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        //called proposaltransaction
        mult.proposalTransaction(to, 3 ether);
        ///owner proposal index
        vm.prank(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        uint256 ind = mult.ownerProposalIndexShow(
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        );
        emit log_uint(ind);
        vm.prank(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        ///revoking the proposal
        mult.revokeProposalTransaction();

        uint256 index = mult.ownerProposalIndex(
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        );
        assertEq(index, 1);
    }

    ///@dev propasal by one , revoke by other
    function test_RevokeProposaltransaction_By_other() public {
        address to = vm.addr(1);
        //ox5b....c4 to msg.sender
        vm.prank(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        //called proposaltransaction
        mult.proposalTransaction(to, 3 ether);
        ///owner proposal index
        vm.prank(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        uint256 ind = mult.ownerProposalIndexShow(
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        );
        emit log_uint(ind);
        vm.prank(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        ///revoking the proposal
        mult.revokeProposalTransaction();
        assertEq(ind, 1);
    }

    ///you didnt proposed any transaction
}
