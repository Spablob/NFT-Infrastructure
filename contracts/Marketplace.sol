// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {TA} from "./TA.sol";
import {TB} from "./TB.sol";
import "hardhat/console.sol";

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Marketplace is ERC1155Holder {
    //===============Variables=============

    TB TBcontract;
    TA TAcontract;
    address payable TBpoolAddress;

    uint256 nrOfferIDs;
    mapping(uint256 => Offer) IDtoOffer;
    struct Offer {
        uint256 offerID;
        uint256 tbID;
        uint256 salePrice;
        uint256 quantity;
        address payable seller;
        bool activeSale;
    }

    //===============Functions=============

    constructor(address payable _TBaddress, address payable _TBpoolAddress, address payable _TAaddress) {
        TBcontract = TB(_TBaddress);
        TAcontract = TA(_TAaddress);
        TBpoolAddress = _TBpoolAddress;
    }

    function listForSale(
        uint256 _tbID,
        uint256 _quantity,
        uint256 _salePrice
    ) external {
        require(TBcontract.balanceOf(msg.sender, _tbID) >= _quantity, "User does not own enough tokens");
        require(
            TAcontract.checkIfTAisActive(TBcontract.getTAid(_tbID), TBcontract.getTBowner(_tbID)) == true,
            "TA license has expired"
        );

        nrOfferIDs++;
        IDtoOffer[nrOfferIDs].offerID = nrOfferIDs;
        IDtoOffer[nrOfferIDs].tbID = _tbID;
        IDtoOffer[nrOfferIDs].salePrice = _salePrice;
        IDtoOffer[nrOfferIDs].quantity = _quantity;
        IDtoOffer[nrOfferIDs].seller = payable(msg.sender);
        IDtoOffer[nrOfferIDs].activeSale = true;

        TBcontract.safeTransferFrom(msg.sender, address(this), _tbID, _quantity, "");
    }

    function buyTB(uint256 _offerID) external payable {
        require(IDtoOffer[_offerID].activeSale == true, "The offer is no longer in the market");
        require(msg.value >= IDtoOffer[_offerID].salePrice, "Not enough ETH");

        IDtoOffer[_offerID].activeSale = false;

        _sendViaCall(
            TBcontract.getTBowner(IDtoOffer[_offerID].tbID),
            (msg.value * TBcontract.getRoyaltyPercentage(IDtoOffer[_offerID].tbID)) / 100
        ); // 15% to TB creator
        _sendViaCall(TAcontract.getTAowner(TBcontract.getTAid(IDtoOffer[_offerID].tbID)), (msg.value * 25) / 1000); // 2.5% to TA owner
        _sendViaCall(TBpoolAddress, (msg.value * 25) / 1000); // 2.5% to TB holders
        _sendViaCall(
            IDtoOffer[_offerID].seller,
            (msg.value * (95 - TBcontract.getRoyaltyPercentage(IDtoOffer[_offerID].tbID))) / 100
        ); // 80% to TB previous owner

        TBcontract.safeTransferFrom(
            address(this),
            msg.sender,
            IDtoOffer[_offerID].tbID,
            IDtoOffer[_offerID].quantity,
            ""
        );
    }

    function _sendViaCall(address payable _to, uint256 _value) private {
        (bool sent, ) = _to.call{value: _value}("");
        require(sent, "Failed to send Ether");
    }

    // function getAllAvailableTBsForSale() external view returns (TBData[] memory);
}
