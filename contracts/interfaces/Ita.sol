// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ITA {
    // structs, events, functions (public and external in contract become external in the interface)

    event TAminted(
        uint256 taID,
        string name,
        string metadataCID,
        uint256 priceToRent,
        uint256 rentingPercentage,
        uint256 rentDuration,
        uint256 amountMinted,
        address payable TAowner
    );
    event TArented(uint256 indexed taID);

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

    /**
     * @dev This function is used to mint TA
     * @notice this function should check if TA is expired before processing payments and mint
     * @param _name IPFS link retrieved from Pinata
     * @param _metadataCID IPFS CID link retrieved from Pinata
     * @param _priceToRent Desired renting price
     * @param _rentingPercentage % renting inflows for TA holder
     * @param _rentDuration what is the duration people can rent
     * @param _amountToMint the amount of NFTs desired to be minted
     **/
    function mintTA(
        string memory _name,
        string memory _metadataCID,
        uint256 _priceToRent,
        uint256 _rentingPercentage,
        uint256 _rentDuration,
        uint256 _amountToMint
    ) external;

    /**
     * @dev This function is used rent a selected TA
     * @notice this function should check if TA is available to be rented
     * @param taID the id of the TA already minted in the "mintTA" function
     **/
    function rentTA(uint256 taID) external payable;
}
