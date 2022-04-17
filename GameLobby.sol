// SPDX-License-Identifier: MIT

pragma solidity >= 0.7 .0 < 0.9 .0;

/// @title BallisticFreaks contract
/// @author Gustas K (ballisticfreaks@gmail.com)

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable,
Ownable {
    event ReferralMint(uint256, address indexed);

    using Strings
    for uint256;

    string public baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    /// @notice edit these before launching contract
    /// @dev only ReferralRewardPercentage & costToCreateReferral is editable
    uint8 public referralRewardPercentage = 50;
    uint256 public cost = 2 ether;
    uint256 public whitelistedCost = 1 ether;
    uint256 public referralCost = 1 ether;
    uint256 public costToCreateReferral = 1 ether;
    uint256 public maxSupply = 10000;

    bool public paused = false;
    bool public revealed = false;
    bool public frozenURI = false;

    mapping(address => uint) public addressesReferred;
    mapping(address => bool) public whitelisted;
    mapping(string => bool) public referralCodeIsTaken;
    mapping(string => address) internal ownerOfCode;

    constructor(string memory _name,
        string memory _symbol,
        string memory _unrevealedURI) ERC721(_name, _symbol) {
        setUnrevealedURI(_unrevealedURI);
    }

    modifier notPaused {
        require(!paused);
        _;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    /// @notice removes Whitelist after the users mints
    function _removeWhitelist(address _address) internal {

        require(whitelisted[_address] == true, "Address is not whitelisted");
        whitelisted[_address] = false;
    }

    /// @notice Chosen code (string) get's assigned to address. Whenever the code is used in mint, assigned address is paid
    function createRefferalCode(address _address, string memory _code) public payable notPaused {
        require(keccak256(abi.encodePacked(_code)) != keccak256(abi.encodePacked("")), "Referral Code can't be empty");
        require(referralCodeIsTaken[_code] != true, "Referral Code is already taken");

        if (msg.sender != owner()) {
            require(msg.value >= costToCreateReferral, "Value should be equal or greater than ReferralCost");
        }

        referralCodeIsTaken[_code] = true;
        ownerOfCode[_code] = _address;
    }

    /// @notice Seperate mint for Whitelisted addresses to not overdue on code complexity. Whitelisted mint allows for only 1 mint
    /// @dev Whitelist allows only 1 mint. After mint removeWhitelist function is called.
    function whitelistedMint() public payable notPaused {
        require(whitelisted[msg.sender], "You are not whitelisted");
        uint256 supply = totalSupply();
        require(supply + 1 <= maxSupply);
        require(msg.value >= whitelistedCost);
        _removeWhitelist(msg.sender);
        _safeMint(msg.sender, supply + 1);

    }

    /// @notice mint function with referral code to give user discount and pay referral
    /// @dev function has an extra input - string. It is used for referral code. If the user does not put any code string looks like this "".
    function mint(address _to, uint256 _mintAmount, string memory _code) public payable notPaused {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);
        require(referralCodeIsTaken[_code] == true || keccak256(abi.encodePacked(_code)) == keccak256(abi.encodePacked("")), "Referral not valid, find a valid code or leave the string empty ");

        if (msg.sender != owner()) {
            if (referralCodeIsTaken[_code] == true) {
                require(ownerOfCode[_code] != msg.sender, "You can't referr yoursef");
                require(msg.value >= (referralCost * _mintAmount), "ReferralMint: Not enough ether");
                emit ReferralMint(_mintAmount, ownerOfCode[_code]);
            } else {
                require(msg.value >= cost * _mintAmount, "MintWithoutReferral: Not enough ether");
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }

        if (referralCodeIsTaken[_code] == true) {
            payable(ownerOfCode[_code]).transfer(msg.value / 100 * referralRewardPercentage);
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    //only owner

    function changeReferralReward(uint8 _percentage) public onlyOwner {
        require(_percentage <= 100);
        referralRewardPercentage = _percentage;
    }

    function changeReferralCost(uint _cost) public onlyOwner {
        costToCreateReferral = _cost;
    }

    function setWhitelist(address _address) public onlyOwner {

        require(whitelisted[_address] == false, "Address is whitelisted");
        whitelisted[_address] = true;
    }

    function freezeURI() public onlyOwner {
        frozenURI = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(!frozenURI, "URI is frozen");
        baseURI = _newBaseURI;
    }

    function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner {
        require(!frozenURI, "URI is frozen");
        notRevealedUri = _unrevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }


    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call {
                value: address(this).balance
            }
            ("");
        require(os);
    }
}
