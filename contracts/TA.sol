// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import {TB} from "./TB.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract TA is ERC1155, Ownable {
    //===============Variables=============

    address payable TBpoolAddress;
    bool defineInstances;

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

    uint256 nrTaIDs;
    mapping(uint256 => TAData) taIDtoData;
    mapping(string => bool) registeredCIDsTA;
    mapping(string => bool) registeredNamesTA;
    mapping(address => mapping(uint256 => uint256)) lastRentingTime;
    mapping(address => mapping(uint256 => bool)) public activeRent;
    mapping(uint256 => uint256) public totalTARented;

    //===============Functions=============

    constructor() ERC1155("") {} //Review this part

    function setInstances(address payable _TBpoolAddress) external onlyOwner {
        require(defineInstances == false, "Cannot set TB contract address twice");
        TBpoolAddress = _TBpoolAddress;
        defineInstances = true;
    }

    function mintTA(
        string memory _name,
        string memory _metadataCID,
        uint256 _priceToRent,
        uint256 _rentingPercentage,
        uint256 _rentDuration,
        uint256 _amountToMint
    ) external {
        require(registeredNamesTA[_name] == false, "Each name can only be minted once");
        require(registeredCIDsTA[_metadataCID] == false, "Each metadataALink can only be minted once");

        nrTaIDs++;
        taIDtoData[nrTaIDs].taID = nrTaIDs;
        taIDtoData[nrTaIDs].name = _name; // eg: Fried Rice
        taIDtoData[nrTaIDs].metadataCID = _metadataCID; // eg: QmTmfTk7N4SBZu2WeUjtMh9CPQvKs4gGH4fjqR5GiMBys9
        taIDtoData[nrTaIDs].priceToRent = _priceToRent;
        taIDtoData[nrTaIDs].rentingPercentage = _rentingPercentage;
        taIDtoData[nrTaIDs].rentDuration = _rentDuration;
        taIDtoData[nrTaIDs].amountMinted = _amountToMint;
        taIDtoData[nrTaIDs].TAowner = payable(msg.sender);

        registeredNamesTA[_name] = true;
        registeredCIDsTA[_metadataCID] = true;

        _mint(msg.sender, nrTaIDs, _amountToMint, "");
    }

    function rentTA(uint256 _taID) external payable {
        require(totalTARented[_taID] < taIDtoData[_taID].amountMinted, "There are no TA NFTs with this ID available");
        require(taIDtoData[_taID].priceToRent <= msg.value, "Not enough ETH was sent");

        require(checkIfTAisActive(_taID, msg.sender) == false, "Each address can only rent 1 TA NFT at a time");

        lastRentingTime[msg.sender][_taID] = block.timestamp;
        activeRent[msg.sender][_taID] = true;
        totalTARented[_taID] += 1;

        _sendViaCall(TBpoolAddress, ((msg.value * (100 - taIDtoData[_taID].rentingPercentage)) / 100));
        _sendViaCall(taIDtoData[_taID].TAowner, ((msg.value * taIDtoData[_taID].rentingPercentage) / 100));
    }

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

    // Review Below function is used to ensuret NFTs visible on outside websites that display NFTs image or video
    function uri(uint256 taID) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://", taIDtoData[taID].metadataCID, "/"));
    }

    function _sendViaCall(address payable _to, uint256 _value) private {
        (bool sent, ) = _to.call{value: _value}("");
        require(sent, "Failed to send Ether");
    }

    function getName(uint256 _taID) external view returns (string memory) {
        return taIDtoData[_taID].name;
    }

    function getTAowner(uint256 _taID) external view returns (address payable) {
        return taIDtoData[_taID].TAowner;
    }
}
