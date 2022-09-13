// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TA} from "./TA.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/**
 * @title TB ERC1155 contract
 * @dev Used to mint TB
 **/
contract TB is ERC1155, Ownable {
    //===============Variables=============
    struct TBData {
        uint256 tbID;
        uint256 taID;
        uint256 mintPrice;
        uint256 royaltyPercentage;
        uint256 salePrice;
        string metadataCID;
        bool markedForSale;
        bool mintEnabled;
        address payable TBowner;
    }

    TA TAcontract;
    address payable tBpoolAddress;
    bool defineInstances;
    uint256 nrTbIDs;

    mapping(uint256 => TBData) tbIDtoData; // stores TBData relative to each TB id
    mapping(bytes => bool) registeredCIDsTB; // stores whether a CID has already been registered
    mapping(bytes => bool) registeredNamesTB; // stores whether a name has already been registered

    //===============Functions=============
    constructor(address _TAaddress) ERC1155("") {
        TAcontract = TA(_TAaddress);
    }

    /**
     * @dev This function defines TB pool address
     * @notice this function should check that only the owner can call it
     * @param _tBpoolAddress address of TB pool
     **/
    function setInstances(address payable _tBpoolAddress) external onlyOwner {
        tBpoolAddress = _tBpoolAddress;
    }

    /**
     * @dev This function is used to enable the minting of new TBs by marketplace participants
     * @notice this function can only be called by TA holder, OR, if rented by the rentee
     * @param _taID the ID of the corresponding TA from which the metadata will be merged
     * @param _nameTB  name of the TB token
     * @param _metadataCID The IPFS link to the merged metadata (TA + TB) - perform merge with NFT.storage first
     * @param _mintPrice Desired minting price
     * @param _royaltyPercentage % desired resale royalty
     **/
    function enableTBMint(
        uint256 _taID,
        string memory _nameTB, 
        string memory _metadataCID,
        uint256 _mintPrice,
        uint256 _royaltyPercentage
    ) external {
        require(TAcontract.checkIfTAisActive(_taID, msg.sender) == true, "This address is not renting this TA id");
        require(_containWord(TAcontract.getName(_taID), bytes(_nameTB)) == true, "TA name must be contained in TB name");
        require(registeredNamesTB[bytes(_nameTB)] == false, "Each name can only be minted once");
        require(registeredCIDsTB[bytes(_metadataCID)] == false, "Each metadataALink can only be minted once");
        require(_royaltyPercentage < 9500 && _royaltyPercentage > 100, "Invalid royalty %");

        nrTbIDs++;
        tbIDtoData[nrTbIDs] = TBData(
            nrTbIDs,
            _taID,
            _mintPrice,
            _royaltyPercentage,
            0,
            _metadataCID,
            false,
            true,
            payable(msg.sender)
        );

        registeredNamesTB[bytes(_nameTB)] = true;
        registeredCIDsTB[bytes(_metadataCID)] = true;
    }

    /**
     * @dev This function is used to mint TBs off a selected TA. TB Minting must be enabled
     * @notice this function should check if TA is expired before processing payments and mint
     * @param _tbID the id of the TB whose enabled TB will be minted
     * @param _quantity the quantity of TB to mint
     **/
    function mintTB(uint256 _tbID, uint256 _quantity) external payable {
        require(tbIDtoData[_tbID].mintEnabled == true, "This TB is not available to mint");
        require(tbIDtoData[_tbID].mintPrice * _quantity == msg.value, "Not enough ETH was sent");
        require(
            TAcontract.checkIfTAisActive(tbIDtoData[_tbID].taID, tbIDtoData[_tbID].TBowner) == true,
            "TA license has expired"
        );

        _sendViaCall(tbIDtoData[nrTbIDs].TBowner, (msg.value * 8000) / 10000); // 80% to TB enabler
        _sendViaCall(TAcontract.getTAowner(tbIDtoData[nrTbIDs].taID), (msg.value * 1000) / 10000); // 10% to TA owner
        _sendViaCall(tBpoolAddress, (msg.value * 1000) / 10000); // The last 10% to TB holders remain in this contract

        _mint(msg.sender, _tbID, _quantity, "");
    }

    function _containWord(bytes memory whatBytes, bytes memory whereBytes) internal pure returns (bool found) {

        //require(whereBytes.length >= whatBytes.length);
        if (whereBytes.length < whatBytes.length) {
            return false;
        }

        found = false;
        for (uint256 i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint256 j = 0; j < whatBytes.length; j++)
                if (whereBytes[i + j] != whatBytes[j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        return found;
    }

    function _sendViaCall(address payable _to, uint256 _value) private {
        (bool sent, ) = _to.call{value: _value}("");
        require(sent, "Failed to send Ether");
    }

    function getTAid(uint256 _tbID) external view returns (uint256) {
        return tbIDtoData[_tbID].taID;
    }

    function getTBowner(uint256 _tbID) external view returns (address payable) {
        return tbIDtoData[_tbID].TBowner;
    }

    function getRoyaltyPercentage(uint256 _tbID) external view returns (uint256) {
        return tbIDtoData[_tbID].royaltyPercentage;
    }
}
