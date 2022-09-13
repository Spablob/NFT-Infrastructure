// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {TB} from "./TB.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/**
 * @title TA ERC1155 contract
 * @dev Used to mint and rent TA
 **/
contract TA is ERC1155, Ownable {
    //===============Variables=============

    struct TAData {
        uint256 taID;
        string name;
        string metadataCID;
        uint256 priceToRent;
        uint256 rentingPercentage;
        uint256 rentDuration;
        uint256 amountMinted;
        address payable TAowner;
    }

    address payable tBpoolAddress;
    bool defineInstances;
    uint256 nrTaIDs;

    mapping(uint256 => TAData) taIDtoData; // stores TAData relative to each TA id
    mapping(bytes => bool) registeredCIDsTA; // stores whether a CID has already been registered
    mapping(bytes => bool) registeredNamesTA; // stores whether a name has already been registered
    mapping(address => mapping(uint256 => uint256)) lastRentingTime; // for each user address stores the last renting time for each TA id
    mapping(address => mapping(uint256 => bool)) public activeRent; // stores whether the rent is still active for a TA id for a give user address
    mapping(uint256 => uint256) public totalTARented; // stores how many tokens are currently being rented for each id

    //===============Functions=============

    constructor() ERC1155("") {}

    /**
     * @dev This function defines TB pool address
     * @notice this function should check that only the owner can call it
     * @param _tBpoolAddress address of TB pool
     **/
    function setInstances(address payable _tBpoolAddress) external onlyOwner {
        tBpoolAddress = _tBpoolAddress;
    }

    /**
     * @dev This function is used to mint TA
     * @notice this function should check if TA is expired before processing payments and mint
     * @param _name IPFS link retrieved from Pinata
     * @param _metadataCID IPFS CID link retrieved from Pinata
     * @param _priceToRent Desired renting price
     * @param _rentingPercentage % renting inflows for TA holder
     * @param _rentDuration what is the duration people can rent
     * @param _amountToMint the amount of NFTs desired to be minted
     **/
    function mintTA(
        string memory _name,
        string memory _metadataCID,
        uint256 _priceToRent,
        uint256 _rentingPercentage,
        uint256 _rentDuration,
        uint256 _amountToMint
    ) external {
        require(registeredNamesTA[bytes(_name)] == false, "Each name can only be minted once");
        require(registeredCIDsTA[bytes(_metadataCID)] == false, "Each metadataALink can only be minted once");

        nrTaIDs++;

        taIDtoData[nrTaIDs] = TAData(
            nrTaIDs,
            _name,
            _metadataCID,
            _priceToRent,
            _rentingPercentage,
            _rentDuration,
            _amountToMint,
            payable(msg.sender)
        );

        registeredNamesTA[bytes(_name)] = true;
        registeredCIDsTA[bytes(_metadataCID)] = true;

        _mint(msg.sender, nrTaIDs, _amountToMint, "");
    }

    /**
     * @dev This function is used rent a selected TA
     * @notice this function should check if TA is available to be rented
     * @param _taID the id of the TA already minted in the "mintTA" function
     **/
    function rentTA(uint256 _taID) external payable {
        require(totalTARented[_taID] < taIDtoData[_taID].amountMinted, "There are no TA NFTs with this ID available");
        require(taIDtoData[_taID].priceToRent == msg.value, "Not enough ETH was sent");
        require(checkIfTAisActive(_taID, msg.sender) == false, "Each address can only rent 1 TA NFT at a time");

        lastRentingTime[msg.sender][_taID] = block.timestamp;
        activeRent[msg.sender][_taID] = true;
        totalTARented[_taID] += 1;

        _sendViaCall(tBpoolAddress, ((msg.value * (10000 - taIDtoData[_taID].rentingPercentage)) / 10000));
        _sendViaCall(taIDtoData[_taID].TAowner, ((msg.value * taIDtoData[_taID].rentingPercentage) / 10000));
    }

    /**
     * @dev This function is used to check if a given address has a TA id corresponding license active or inactive
     * @param _taID the id of the TA already minted in the "mintTA" function
     * @param _addressToCheck is the user address which will be checked for active/inactive renting license
    **/
    function checkIfTAisActive(uint256 _taID, address _addressToCheck) public returns (bool) {
        if (activeRent[_addressToCheck][_taID] == true) {
            if (block.timestamp > lastRentingTime[_addressToCheck][_taID] + taIDtoData[nrTaIDs].rentDuration) {
                activeRent[_addressToCheck][_taID] = false;
                totalTARented[_taID] -= 1;
                return false;
            }
            return true;
        }
        return false;
    }

    /**
     * @dev This function is used return a link to check IPFS data online
     * @param _taID the id of the TA already minted in the "mintTA" function
    **/
    function uri(uint256 _taID) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://", taIDtoData[_taID].metadataCID, "/"));
    }

    function _sendViaCall(address payable _to, uint256 _value) private {
        (bool sent, ) = _to.call{value: _value}("");
        require(sent, "Failed to send Ether");
    }

    function getName(uint256 _taID) external view returns (bytes memory) {
        return bytes(taIDtoData[_taID].name);
    }

    function getTAowner(uint256 _taID) external view returns (address payable) {
        return taIDtoData[_taID].TAowner;
    }
}
