// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {TA} from "./TA.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract TB is ERC1155, Ownable {
    //===============Variables=============
    TA TAcontract;
    address payable TBpoolAddress;
    bool defineInstances;

    uint256 nrTbIDs;
    mapping(uint256 => TBData) tbIDtoData;
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

    mapping(string => bool) registeredCIDsTB;
    mapping(string => bool) registeredNamesTB;

    //===============Functions=============
    constructor(address _TAaddress) ERC1155("") {
        TAcontract = TA(_TAaddress);
    }

    function setInstances(address payable _TBpoolAddress) external onlyOwner {
        require(defineInstances == false, "Cannot set TB contract address twice");
        TBpoolAddress = _TBpoolAddress;
        defineInstances = true;
    }

    function enableTBMint(
        uint256 _taID,
        string memory _nameTB, // Malaysian Fried Rice
        string memory _metadataCID,
        uint256 _mintPrice,
        uint256 _royaltyPercentage
    ) external {
        require(TAcontract.checkIfTAisActive(_taID, msg.sender) == true, "This address is not renting this TA id");
        require(_containWord(TAcontract.getName(_taID), _nameTB) == true, "TA name must be contained in TB name");
        require(registeredNamesTB[_nameTB] == false, "Each name can only be minted once");
        require(registeredCIDsTB[_metadataCID] == false, "Each metadataALink can only be minted once");
        require(_royaltyPercentage < 95, "Exceeded royalty % limit");

        nrTbIDs++;
        tbIDtoData[nrTbIDs].tbID = nrTbIDs;
        tbIDtoData[nrTbIDs].taID = _taID;
        tbIDtoData[nrTbIDs].mintPrice = _mintPrice;
        tbIDtoData[nrTbIDs].royaltyPercentage = _royaltyPercentage;
        tbIDtoData[nrTbIDs].metadataCID = _metadataCID;
        tbIDtoData[nrTbIDs].mintEnabled = true;
        tbIDtoData[nrTbIDs].TBowner = payable(msg.sender);

        registeredNamesTB[_nameTB] = true;
        registeredCIDsTB[_metadataCID] = true;
    }

    function mintTB(uint256 _tbID, uint256 _quantity) external payable {
        require(tbIDtoData[_tbID].mintEnabled == true, "This TB is not available to mint");
        require(tbIDtoData[_tbID].mintPrice * _quantity <= msg.value, "Not enough ETH was sent");
        require(
            TAcontract.checkIfTAisActive(tbIDtoData[_tbID].taID, tbIDtoData[_tbID].TBowner) == true,
            "TA license has expired"
        );

        _sendViaCall(tbIDtoData[nrTbIDs].TBowner, (msg.value * 80) / 100); // 80% to TB enabler
        _sendViaCall(TAcontract.getTAowner(tbIDtoData[nrTbIDs].taID), (msg.value * 10) / 100); // 10% to TA owner
        _sendViaCall(TBpoolAddress, (msg.value * 10) / 100); // The last 10% to TB holders remain in this contract

        _mint(msg.sender, _tbID, _quantity, "");
    }

    function _containWord(string memory what, string memory where) internal pure returns (bool found) {
        bytes memory whatBytes = bytes(what);
        bytes memory whereBytes = bytes(where);

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

    // Review Add unstaking rewards part
    // Used to receive TB owners share of (i) TA renting and (ii) TB royalties

    //function getAllAvailableTBsToMint() external view returns (TBData[] memory);
}
