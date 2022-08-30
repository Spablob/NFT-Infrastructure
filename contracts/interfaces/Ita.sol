pragma solidity 0.8.16;

interface Ita { // structs, events, functions (public and external in contract become external in the interface)
    
    event TAminted(uint256 indexed taID, string metadataALink, uint256 priceToRent, uint256 rentingPercentage, uint256 timeOfExpiry);

    /// @dev This function is used to mint TA
    /// @param metadataALink IPFS link retrieved from Pinata
    /// @param priceToRent Desired renting price
    /// @param rentingPercentage % renting inflows for TA holder
    /// @param timeOfExpiry future timestamp when the rent expires (s)
    function mintTA(string memory metadataALink, uint256 priceToRent, uint256 rentingPercentage, uint256 timeOfExpiry) external;

    

    // function rentTA();
}