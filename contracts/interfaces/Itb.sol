// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

/**
 * @title TB interface contract contract
 * @dev Main point of interaction the TB contracts
 **/
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
    function setInstances(address payable _TBpoolAddress) external;

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
        string memory _nameTB, // eg. Malaysian Fried Rice
        string memory _metadataCID,
        uint256 _mintPrice,
        uint256 _royaltyPercentage
    ) external;

    /**
     * @dev This function is used to mint TBs off a selected TA. TB Minting must be enabled
     * @notice this function should check if TA is expired before processing payments and mint
     * @param _tbID the id of the TB whose enabled TB will be minted
     * @param _quantity the quantity of TB to mint
     **/
    function mintTB(uint256 _tbID, uint256 _quantity) external;

    /**
     * @dev This function returns the taID from which a certain tbID originates
     * @param _tbID the id of a TB of choice
     **/
    function getTAid(uint256 _tbID) external;

    /**
     * @dev This function returns the address that minted a certain tbID
     * @param _tbID the id of a TB of choice
     **/
    function getTBowner(uint256 _tbID) external;

    /**
     * @dev This function returns the % that minter defined as royalty given a certain tbID
     * @param _tbID the id of a TB of choice
     **/
    function getRoyaltyPercentage(uint256 _tbID) external;

    /**
     * @dev This function returns an array of all TBs which are available to mint
     * @notice This is an expensive view call but for demonstration purposes it works. Alternate solution is to build a subgraph
     **/
    // function getAllAvailableTBsToMint() external view returns (TBData[] memory);
}
