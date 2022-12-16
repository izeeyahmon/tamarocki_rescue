// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/TamarockiRescue.sol";
import {console} from "forge-std/console.sol";
import {ECDSA} from "@openzeppelin/utils/cryptography/ECDSA.sol";

interface CheatCodes {
    function addr(uint256) external returns (address);
    function startPrank(address sender, address origin) external;
    function stopPrank() external;
    function prank(address) external;
    function expectRevert() external;
    function deal(address who, uint256 newBalance) external;
    // function sign(uint256 privateKey, bytes32 digest) external returns (uint8 v, bytes32 r, bytes32 s);
}

contract TamarockiRescueTest is Test {
    using ECDSA for bytes32;

    TamarockiRescue tamarockiRescue;
    address public tester1;
    address public tester2;
    address public tester3;
    bool public state;
    CheatCodes cheat = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        tamarockiRescue =
            new TamarockiRescue('https://test.com','https://test.com',0xad6DD2aA32850e57a0986f18f654Dd90dAB39D6c);
        tamarockiRescue.setSaleState(true);
        tamarockiRescue.setOGSaleState(true);
        tester1 = cheat.addr(1);
        tester2 = cheat.addr(2);
        tester3 = cheat.addr(3);
        cheat.startPrank(tester1, tester1);
        cheat.deal(tester1, 500 ether);
    }

    function testpublicMint() public {
        tamarockiRescue.publicMint{value: 0.1 ether}(1);
        tamarockiRescue.publicMint{value: 0.5 ether}(5);
    }

    function testtokenUri() public {
        tamarockiRescue.publicMint{value: 0.1 ether}(1);
        assertEq(tamarockiRescue.tokenURI(0), "https://test.com");
    }

    function testPublicMintOverSupply() public {
        vm.expectRevert();
        tamarockiRescue.publicMint{value: 290.1 ether}(2901);
    }

    /*  function testOGMint() public {
        // bytes memory stest = Cast::keccak256('0x618349d78a70e4933935e189d316398f762fd056d2287617ebb8ba16289850af25bd4cd9e22e7e7fea24d999bc0c9e7d6bc190ad2c80c7083f2472937142beb81c');

        bytes memory sig =
            "0x618349d78a70e4933935e189d316398f762fd056d2287617ebb8ba16289850af25bd4cd9e22e7e7fea24d999bc0c9e7d6bc190ad2c80c7083f2472937142beb81c";
        // console.logBytes(abi.encode(tester1, 1));
        0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f.call{value: 0.1 ether}(
            abi.encodeWithSignature("ogMint(uint256,bytes)", 1, sig)
        );
        tamarockiRescue.ogMint{value: 0.1 ether}(1, sig);
    } */
}
