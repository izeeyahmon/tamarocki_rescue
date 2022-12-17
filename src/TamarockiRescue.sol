// SPDX-License-Identifier: GPL-3.0

/*===================================================
    _______
   /       \
  /         \
 | Tamarocki |
 |  Rescue   |
  \         /
   \_______/
=====================================================*/
pragma solidity ^0.8.15;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {OperatorFilterer} from "closedsea/Operatorfilterer.sol";
import {ERC2981} from "@openzeppelin/token/common/ERC2981.sol";

contract TamarockiRescue is ERC721A, Ownable, OperatorFilterer, ERC2981 {
    /* Setting the Variables */
    using ECDSA for bytes32;

    string baseURI;
    string baseExtension = ".json";
    string notRevealedUri;
    bool saleLive;
    bool ogSaleLive;
    bool perdaysaleLive;
    bool isRevealed;
    bool public operatorFilteringEnabled;
    uint256 counterPerDay;
    uint256 public perdayTimestamp;

    uint256 public constant maxRockSupply = 10001;
    // uint8 public constant allowance = 2;
    uint256 constant ogRocks = 101;
    uint256 constant perdayRocks = 10;
    uint256 constant publicSupply = 2900;
    uint256 constant price = 0.1 ether;
    //Signer address for the hash
    address private immutable _signerAddress;
    //Not used
    mapping(address => uint256) public Minted;

    constructor(string memory _BaseURI, string memory _NotRevealedUri, address signerAddress_)
        ERC721A("TamarockiRescue", "TAMAROCKI")
    {
        setBaseURI(_BaseURI);
        setNotRevealedURI(_NotRevealedUri);
        _signerAddress = signerAddress_;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
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

    function perdaysaleLiveState(bool _state) public onlyOwner {
        perdaysaleLive = _state;
        perdayTimestamp = block.timestamp;
    }

    function reveal(bool _state) public onlyOwner {
        isRevealed = _state;
    }

    function overriderockperDay() public onlyOwner {
        counterPerDay = 0;
    }

    /* Operator Filterer Area*/

    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        // This is to enable or disable the operator filtering
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    /* This is the OG Mint without an auction */
    /* Note :to izee test multiple mints with less than the allowed if its allowed 
    test also if condensing the two if statements save gas it shouldn't since it would an OR opcode
    Also there is no restriction yet for max amount of TX'es per mint*/
    function ogMint(uint256 amount, bytes calldata signature) public payable {
        if (!ogSaleLive) revert SaleNotLive(); // Check if sale is live
        unchecked {
            if (totalSupply() + amount > ogRocks) revert OverMintLimit(); // This is to limit it to 101 initial sale, unchecked also since it will cost them a great amount of money to overflow
        }
        if (msg.value < amount * price) revert InvalidMsgValue(); // Check Price is correct
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

    function newmintperDay(uint256 _mintAmount, bytes calldata signature) public payable callerIsUser {
        if (!perdaysaleLive) revert SaleNotLive();
        if (block.timestamp < perdayTimestamp) revert SaleNotLive();
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encode(msg.sender, _mintAmount)));
        if (ECDSA.recover(hash, signature) == _signerAddress) {
            revert InvalidSignature();
        }
        unchecked {
            if (msg.value < _mintAmount * price) revert InvalidMsgValue();
            if (totalSupply() + _mintAmount > maxRockSupply) revert OverMintLimit();
        }
        if (counterPerDay + _mintAmount > perdayRocks) revert OverMintLimit();
        counterPerDay += _mintAmount;
        _mint(msg.sender, _mintAmount);
        if (counterPerDay == perdayRocks) {
            perdayTimestamp = block.timestamp + 1 days;
            counterPerDay = 0;
        }
    }

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
        if (!success) revert TransferFailed();
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
