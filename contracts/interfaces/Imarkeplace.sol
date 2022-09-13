// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

interface IMarketplace {
    event TBListedForSale(uint256 indexed tbID, uint256 quantity, uint256 salePrice);
    event TBBought(uint256 indexed tbID, uint256 quantity);

    struct Offer {
        uint256 offerID;
        uint256 tbID;
        uint256 salePrice;
        uint256 quantity;
        address payable seller;
        bool activeSale;
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
    ) external;

    /**
     * @dev This function is used to buy a certain available quantity of a given TB Id
     * @param _offerID the id of the offer being purchased
     **/
    function buyTB(uint256 _offerID) external;

    /**
     * @dev This function returns an array of all TBs which are available for sale
     * @notice This is an expensive view call but for demonstration purposes it works. Alternate solution is to build a subgraph
     **/
    // function getAllAvailableTBsForSale() external view returns (TBData[] memory);
}
