// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title TA interface contract contract
 * @dev Main point of interaction the TA contract
 **/
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
        uint256 totalRented;
        address payable TAowner;
    }

    /**
     * @dev This function defines TB pool address
     * @notice this function should check that only the owner can call it
     * @param _tBpoolAddress address of TB pool
     **/
    function setInstances(address payable _tBpoolAddress) external;

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
     * @param _taID the id of the TA already minted in the "mintTA" function
     **/
    function rentTA(uint256 _taID) external payable;

    /**
     * @dev This function is used to check if a given address has a TA id corresponding license active or inactive
     * @param _taID the id of the TA already minted in the "mintTA" function
     * @param _addressToCheck is the user address which will be checked for active/inactive renting license
     **/
    function checkIfTAisActive(uint256 _taID, address _addressToCheck) external returns (bool);

    /**
     * @dev This function is to get all the data of a given TA
     * @param _taID the target TA±
     **/
    function getTA(uint256 _taID)
        external
        view
        returns (
            string memory name,
            string memory metadataCID,
            uint256 priceToRent,
            uint256 rentingPercentage,
            uint256 rentDuration,
            uint256 amountMinted,
            uint256 totalRented,
            address payable TAowner
        );

    /**
     * @dev This function is used to get all available TAs to rent, filtering by null rentee addresses
     **/
    function getAllAvailableTAtoRent()
        external
        view
        returns (TAData[] memory availableTAsData, uint256[] memory totalAvailableToRent);

    /**
     * @dev This function is used to get all TAs available to rent by the target
     * @param _target the target address to filter
     **/
    function getTargetAvailableToRentTAs(address _target)
        external
        view
        returns (TAData[] memory targetAvailableToRentTAs, uint256[] memory totalAvailableToRent);

    /**
     * @dev This function is used to get all active TAs rented by the target
     * @param _target the target address to filter
     **/
    function getTargetActiveRentedTAs(address _target)
        external
        view
        returns (TAData[] memory targetActiveRentedTAsData, uint256[] memory remainingActiveTime);

    /**
     * @dev This function is used to get all TAs rented by the target in its lifetime
     * @param _target the target address to filter
     **/
    function getTargetLifetimeRentedTAs(address _target)
        external
        view
        returns (TAData[] memory targetLifetimeRentedTAsData);

    /**
     * @dev To get the TB pool address
     **/
    function getTBpoolAddress() external view returns (address payable);

    /**
     * @dev This function returns the bytes representation of a name
     * @param _taID the id of a TA of choice
     **/
    function getName(uint256 _taID) external view returns (bytes memory);

    /**
     * @dev This function returns if the rent is active for a given TA
     * @param _target the address of the target rentee
     * @param _taID the id of a TA of choice
     **/
    function getActiveRent(address _target, uint256 _taID) external view returns (bool);

    /**
     * @dev This function returns the last renting time for a given ta
     * @param _target the address of the target rentee
     * @param _taID the id of a TA of choice
     **/
    function getLastRentingTime(address _target, uint256 _taID) external view returns (uint256);

    /**
     * @dev This function returns the address that minted a certain taID
     * @param _taID the id of a TA of choice
     **/
    function getTAowner(uint256 _taID) external view returns (address payable);
}
