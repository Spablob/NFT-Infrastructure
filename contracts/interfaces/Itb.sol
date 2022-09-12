// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

interface ITB {
    event TBMintEnabled(
        uint256 indexed tbID,
        uint256 indexed taID,
        uint256 mintPrice,
        uint256 royaltyPercentage,
        uint256 salePrice,
        string metadataCID,
        bool markedForSale,
        bool mintEnabled,
        address payable TBowner
    );
    event TBMinted(uint256 indexed tbID, uint256 quantity);

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

    /**
     * @dev This function allows TB contract to send rewards to the correct TB pool address
     * @notice this function can only be called by contract deployer
     * @param _TBpoolAddress the address of the pool where TB holders harvest their rewards
     **/
    function setInstances(address payable _TBpoolAddress) external onlyOwner;

    /**
     * @dev This function is used to enable the minting of new TBs by marketplace participants
     * @notice this function can only be called by TA holder, OR, if rented by the rentee
     * @param name of the TB token
     * @param taID the ID of the corresponding TA from which the metadata will be merged
     * @param metadataTB The IPFS link to the merged metadata (TA + TB) - perform merge with NFT.storage first
     * @param mintPrice Desired minting price
     * @param resaleRoyalty % desired resale royalty
     **/
    function enableTBMint(
        uint256 _taID,
        string memory _nameTB, // eg. Malaysian Fried Rice
        string memory _metadataCID,
        uint256 _mintPrice,
        uint256 _royaltyPercentage
    ) external;

    /**
     * @dev This function is used to mint TBs off a selected TA. TB Minting must be enabled
     * @notice this function should check if TA is expired before processing payments and mint
     * @param taID the id of the TA whose enabled TB will be minted
     * @param quantity the quantity of TB to mint
     **/
    function mintTB(uint256 taID, uint256 quantity) external;

    /**
     * @dev This function returns the taID from which a certain tbID originates
     * @param tbID the id of a TB of choice
     **/
    function getTAid(uint256 _tbID) external;

    /**
     * @dev This function returns the address that minted a certain tbID
     * @param tbID the id of a TB of choice
     **/
    function getTBowner(uint256 _tbID) external;

    /**
     * @dev This function returns the % that minter defined as royalty given a certain tbID
     * @param tbID the id of a TB of choice
     **/
    function getRoyaltyPercentage(uint256 _tbID) external;
    /**
     * @dev This function returns an array of all TBs which are available to mint
     * @notice This is an expensive view call but for demonstration purposes it works. Alternate solution is to build a subgraph
     **/
    // function getAllAvailableTBsToMint() external view returns (TBData[] memory);


}
