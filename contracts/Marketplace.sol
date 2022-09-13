// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TA} from "./TA.sol";
import {TB} from "./TB.sol";
import "hardhat/console.sol";

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @title TB Marketplace contract
 * @dev Used to buy and sell TB tokens
 **/
contract Marketplace is ERC1155Holder {
    //===============Variables=============

    struct OfferData {
        uint256 offerID;
        uint256 tbID;
        uint256 salePrice;
        uint256 quantity;
        address payable seller;
        bool activeSale;
    }

    TA TAcontract;
    TB TBcontract;

    address payable tBpoolAddress;
    uint256 nrOfferIDs;

    mapping(uint256 => OfferData) idtoOffer; // stores offer data for each offer id

    //===============Functions=============

    constructor(
        address payable _TBaddress,
        address payable _tBpoolAddress,
        address payable _TAaddress
    ) {
        TBcontract = TB(_TBaddress);
        TAcontract = TA(_TAaddress);
        tBpoolAddress = _tBpoolAddress;
    }

    /**
     * @dev This function is used to list a certain quantity of TBs for sale, with a given price
     * @notice A check for TA expiry must be made
     * @param _tbID the id of the TB which will be listed
     * @param _quantity quantity of TB to be listed
     * @param _salePrice price of each TB to be listed
     **/
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
        idtoOffer[nrOfferIDs] = OfferData(nrOfferIDs, _tbID, _salePrice, _quantity, payable(msg.sender), true);

        TBcontract.safeTransferFrom(msg.sender, address(this), _tbID, _quantity, "");
    }

    /**
     * @dev This function is used to buy a certain available quantity of a given TB Id
     * @param _offerID the id of the offer being purchased
     **/
    function buyTB(uint256 _offerID) external payable {
        require(idtoOffer[_offerID].activeSale == true, "The offer is no longer in the market");
        require(msg.value == idtoOffer[_offerID].salePrice, "Not enough ETH");

        idtoOffer[_offerID].activeSale = false;

        _sendViaCall(
            TBcontract.getTBowner(idtoOffer[_offerID].tbID),
            (msg.value * TBcontract.getRoyaltyPercentage(idtoOffer[_offerID].tbID)) / 10000
        ); // 15% to TB creator
        _sendViaCall(TAcontract.getTAowner(TBcontract.getTAid(idtoOffer[_offerID].tbID)), (msg.value * 2500) / 100000); // 2.5% to TA owner
        _sendViaCall(tBpoolAddress, (msg.value * 2500) / 100000); // 2.5% to TB holders
        _sendViaCall(
            idtoOffer[_offerID].seller,
            (msg.value * (9500 - TBcontract.getRoyaltyPercentage(idtoOffer[_offerID].tbID))) / 10000
        ); // 80% to TB previous owner

        TBcontract.safeTransferFrom(
            address(this),
            msg.sender,
            idtoOffer[_offerID].tbID,
            idtoOffer[_offerID].quantity,
            ""
        );
    }

    function _sendViaCall(address payable _to, uint256 _value) private {
        (bool sent, ) = _to.call{value: _value}("");
        require(sent, "Failed to send Ether");
    }
}
