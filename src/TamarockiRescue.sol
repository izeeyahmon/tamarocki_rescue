// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";

contract TamarockiRescue is ERC721A, Ownable {
    /* Setting the Variables */
    using ECDSA for bytes32;

    string baseURI;
    string baseExtension = ".json";
    string notRevealedUri;
    bool saleLive;
    bool ogSaleLive;
    bool isRevealed;
    bool finalPhase;

    uint256 public constant maxRockSupply = 10001;
    uint8 public constant allowance = 2;
    uint256 constant ogRocks = 101;
    uint256 constant publicSupply = 2900;
    uint256 constant price = 0.1 ether;

    address private immutable _signerAddress;

    mapping(address => uint256) public Minted;

    constructor(string memory _BaseURI, string memory _NotRevealedUri, address signerAddress_)
        ERC721A("TamarockiRescue", "TAMAROCKI")
    {
        setBaseURI(_BaseURI);
        setNotRevealedURI(_NotRevealedUri);
        _signerAddress = signerAddress_;
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert NOTEOA();
        _;
    }

    /*================= Utilities Area ================= */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string calldata _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        if (isRevealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
            : "";
    }

    function setSaleState(bool _state) public onlyOwner {
        saleLive = _state;
    }

    function setOGSaleState(bool _state) public onlyOwner {
        ogSaleLive = _state;
    }

    function reveal(bool _state) public onlyOwner {
        isRevealed = _state;
    }

    /* This is the OG Mint without an auction */
    /* Note :to izee test multiple mints with less than the allowed if its allowed 
    test also if condensing the two if statements save gas it shouldn't since it would an OR opcode
    Also there is no restriction yet for max amount of TX'es per mint*/
    function ogMint(uint256 amount, bytes calldata signature) public payable {
        if (!ogSaleLive) revert SaleNotLive(); // Check if sale is live
        if (totalSupply() + amount > ogRocks) revert OverMintLimit();
        if (msg.value < amount * price) revert InvalidMsgValue();
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encode(msg.sender, amount)));
        if (ECDSA.recover(hash, signature) == _signerAddress) {
            revert InvalidSignature();
        }

        _mint(msg.sender, amount);
    }

    /* Need to check if there is any max amount per tx */
    function publicMint(uint256 _mintAmount) public payable callerIsUser {
        if (!saleLive) revert SaleNotLive(); //ensure Public Mint is on
        unchecked {
            if (msg.value < _mintAmount * price) revert InvalidMsgValue();
            if (totalSupply() + _mintAmount > publicSupply) revert OverMintLimit(); // This is to limit it to 2900 initial sale
        }
        _mint(msg.sender, _mintAmount);
    }
    /* Final phase that releases 10 rocks per day with only qualified members that are allowed */

    function mintPerDay() public payable {}

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                transferFrom(_from, _to, _tokenIds[i]);
            }
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                safeTransferFrom(_from, _to, _tokenIds[i], data_);
            }
        }
    }

    function withdraw() external payable onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        if (success) revert TransferFailed();
    }
}

error Unauthorized();
error NOTEOA();
error OverMintLimit();
error InvalidSignatureBuyAmount();
error InvalidSignature();
error InvalidMsgValue();
error SaleNotLive();
error TransferFailed();
