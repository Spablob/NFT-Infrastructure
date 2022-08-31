// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

interface ITB {
    event TBMintEnabled(
        uint256 indexed taID,
        uint256 indexed tbID,
        string metadata,
        uint256 mintPrice,
        uint256 resaleRoyalty
    );
    event TBMinted(uint256 indexed tbID, uint256 quantity);
    event TBListedForSale(uint256 indexed tbID, uint256 quantity, uint256 salePrice);
    event TBBought(uint256 indexed tbID, uint256 quantity);

    struct TBData {
        uint256 taID;
        uint256 mintPrice;
        uint256 resaleRoyalty;
        uint256 salePrice;
        string metadataTB;
        bool markedForSale;
        bool mintEnabled;
    }

    /**
     * @dev This function is used to enable the minting of new TBs by marketplace participants
     * @notice this function can only be called by TA holder, OR, if rented by the rentee
     * @param taID the ID of the corresponding TA from which the metadata will be merged
     * @param metadataTB The IPFS link to the merged metadata (TA + TB) - perform merge with NFT.storage first
     * @param mintPrice Desired minting price
     * @param resaleRoyalty % desired resale royalty
     **/
    function enableTBMint(
        uint256 taID,
        string memory metadataTB,
        uint256 mintPrice,
        uint256 resaleRoyalty
    ) external;

    /**
     * @dev This function is used to mint TBs off a selected TA. TB Minting must be enabled
     * @notice this function should check if TA is expired before processing payments and mint
     * @param taID the id of the TA whose enabled TB will be minted
     * @param quantity the quantity of TB to mint
     **/
    function mintTB(uint256 taID, uint256 quantity) external;

    /**
     * @dev This function is used to list a certain quantity of TBs for sale, with a given price
     * @notice A check for TA expiry must be made
     * @param tbID the id of the TB which will be listed
     * @param quantity quantity of TB to be listed
     * @param salePrice price of each TB to be listed
     **/
    function listForSale(
        uint256 tbID,
        uint256 quantity,
        uint256 salePrice
    ) external;

    /**
     * @dev This function is used to buy a certain available quantity of a given TB Ide
     * @notice A check for TA expiry must be made
     * @param tbID the id of the TB which will be bought
     * @param quantity quantity of TB to be bought
     **/
    function buyTB(uint256 tbID, uint256 quantity) external;

    /**
     * @dev This function returns an array of all TBs which are available to mint
     * @notice This is an expensive view call but for demonstration purposes it works. Alternate solution is to build a subgraph
     **/
    function getAllAvailableTBsToMint() external view returns (TBData[] memory);

    /**
     * @dev This function returns an array of all TBs which are available for sale
     * @notice This is an expensive view call but for demonstration purposes it works. Alternate solution is to build a subgraph
     **/
    function getAllAvailableTBsForSale() external view returns (TBData[] memory);
}
