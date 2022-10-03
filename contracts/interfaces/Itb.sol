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
        string name;
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
    function setInstances(address payable _TBpoolAddress, address payable _marketplaceAddress) external;

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
    function mintTB(uint256 _tbID, uint256 _quantity) external payable;

    /**
     * @dev This function returns the taID from which a certain tbID originates
     * @param _tbID the id of a TB of choice
     **/
    function getTAid(uint256 _tbID) external view returns (uint256);

    /**
     * @dev This function is to get all the data of a given TB
     * @param _tbID the target TB
     **/
    function getTB(uint256 _tbID)
        external
        view
        returns (
            uint256 taID,
            uint256 mintPrice,
            uint256 royaltyPercentage,
            uint256 salePrice,
            string memory name,
            string memory metadataCID,
            bool markedForSale,
            bool mintEnabled,
            address payable TBowner
        );

    /**
     * @dev Returns true if name is registered, false otherwise
     * @param _name the name to check
     **/
    function isRegisteredName(string memory _name) external view returns (bool);

    /**
     * @dev Returns true if cid is registered, false otherwise
     * @param _cid the cid to check
     **/
    function isRegisteredMetadata(string memory _cid) external view returns (bool);

    /**
     * @dev This function returns the address that minted a certain tbID
     * @param _tbID the id of a TB of choice
     **/
    function getTBowner(uint256 _tbID) external view returns (address payable);

    /**
     * @dev This function returns the % that minter defined as royalty given a certain tbID
     * @param _tbID the id of a TB of choice
     **/
    function getRoyaltyPercentage(uint256 _tbID) external view returns (uint256);

    /**
     * @dev This function is used to get all TBs available to mint
     **/
    function getAllAvailableTBsToMint()
        external
        view
        returns (TBData[] memory allAvailableTBsToMint, uint256[] memory remainingActiveTime);

    /**
     * @dev Returns the TB pool address
     **/
    function getTBpoolAddress() external view returns (address payable);

    /**
     * @dev Returns if the address has minted or bought a particular token TB
     * @param _target the address to target
     * @param _tbID the target TB
     **/
    function getHasMinted(address _target, uint256 _tbID) external view returns (bool);

    /**
     * @dev Updates with new purchases made
     * @param _target the address to target
     * @param _tbID the target TB
     **/
    function updateHasMintedOrOwned(address _target, uint256 _tbID) external;

    /**
     * @dev This function is used to get all TBs that an address has minted since ever
     * @param _target the address to target
     **/
    function getLifetimeMintedTBs(address _target)
        external
        view
        returns (
            TBData[] memory targetMintedTbs,
            uint256[] memory quantity,
            uint256[] memory remainingActiveTime
        );
}
