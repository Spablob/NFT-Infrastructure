// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {ITA} from "./interfaces/Ita.sol";
import {TB} from "./TB.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TA ERC1155 contract
 * @dev Used to mint and rent TA
 **/
contract TA is ERC1155, Ownable, ITA {
    //===============Variables=============

    address payable tBpoolAddress;
    bool defineInstances;
    uint256 nrTaIDs;

    mapping(uint256 => TAData) taIDtoData; // stores TAData relative to each TA id
    mapping(bytes => bool) registeredCIDsTA; // stores whether a CID has already been registered
    mapping(bytes => bool) registeredNamesTA; // stores whether a name has already been registered
    mapping(address => mapping(uint256 => uint256)) lastRentingTime; // for each user address stores the last renting time for each TA id
    mapping(address => mapping(uint256 => bool)) public activeRent; // stores whether the rent is still active for a TA id for a give user address
    mapping(uint256 => address[]) public taRentees; // stores all the rentees, active or not, for a given TA
    mapping(address => uint256[]) public rentedTAs; // stores all the TA ids an address has rented
    mapping(address => mapping(uint256 => bool)) public hasRented;

    //===============Functions=============

    constructor() ERC1155("") {}

    /**
     * @dev This function defines TB pool address
     * @notice this function should check that only the owner can call it
     * @param _tBpoolAddress address of TB pool
     **/
    function setInstances(address payable _tBpoolAddress) external override onlyOwner {
        tBpoolAddress = _tBpoolAddress;
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
    ) external override {
        require(registeredNamesTA[bytes(_name)] == false, "Each name can only be minted once");
        require(registeredCIDsTA[bytes(_metadataCID)] == false, "Each metadataALink can only be minted once");
        require(_rentDuration > 0, "Rent duration must be at least 1 second");

        nrTaIDs++;

        taIDtoData[nrTaIDs] = TAData(
            nrTaIDs,
            _name,
            _metadataCID,
            _priceToRent,
            _rentingPercentage,
            _rentDuration,
            _amountToMint,
            0,
            payable(msg.sender)
        );

        registeredNamesTA[bytes(_name)] = true;
        registeredCIDsTA[bytes(_metadataCID)] = true;

        _mint(msg.sender, nrTaIDs, _amountToMint, "");
    }

    /**
     * @dev This function is used rent a selected TA
     * @notice this function should check if TA is available to be rented
     * @param _taID the id of the TA already minted in the "mintTA" function
     **/
    function rentTA(uint256 _taID) external payable override {
        TAData memory ta = taIDtoData[_taID];
        require(checkIfTAisActive(_taID, msg.sender) == false, "Each address can only rent 1 TA NFT at a time");
        require(ta.totalRented < ta.amountMinted, "There are no TA NFTs with this ID available");
        require(ta.priceToRent == msg.value, "Not enough ETH was sent");

        lastRentingTime[msg.sender][_taID] = block.timestamp;
        activeRent[msg.sender][_taID] = true;

        if (!hasRented[msg.sender][_taID]) {
            hasRented[msg.sender][_taID] = true;
            taRentees[_taID].push(msg.sender);
            rentedTAs[msg.sender].push(_taID);
        }

        taIDtoData[_taID].totalRented += 1;

        _sendViaCall(tBpoolAddress, ((msg.value * (10000 - ta.rentingPercentage)) / 10000));
        _sendViaCall(ta.TAowner, ((msg.value * ta.rentingPercentage) / 10000));
    }

    /**
     * @dev This function is used to check if a given address has a TA id corresponding license active or inactive
     * @param _taID the id of the TA already minted in the "mintTA" function
     * @param _addressToCheck is the user address which will be checked for active/inactive renting license
     **/
    function checkIfTAisActive(uint256 _taID, address _addressToCheck) public override returns (bool) {
        if (activeRent[_addressToCheck][_taID] == true) {
            if (block.timestamp > lastRentingTime[_addressToCheck][_taID] + taIDtoData[_taID].rentDuration) {
                activeRent[_addressToCheck][_taID] = false;
                taIDtoData[_taID].totalRented -= 1;

                return false;
            }
            return true;
        }
        return false;
    }

    /**
     * @dev This function is used return a link to check IPFS data online
     * @param _taID the id of the TA already minted in the "mintTA" function
     **/
    function uri(uint256 _taID) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://", taIDtoData[_taID].metadataCID, "/"));
    }

    /**
     * @dev This function is to get all the data of a given TA
     * @param _taID the target TA±
     **/
    function getTA(uint256 _taID)
        external
        view
        override
        returns (
            string memory name,
            string memory metadataCID,
            uint256 priceToRent,
            uint256 rentingPercentage,
            uint256 rentDuration,
            uint256 amountMinted,
            uint256 totalRented,
            address payable TAowner
        )
    {
        TAData memory ta = taIDtoData[_taID];

        name = ta.name;
        metadataCID = ta.metadataCID;
        priceToRent = ta.priceToRent;
        rentingPercentage = ta.rentingPercentage;
        rentDuration = ta.rentDuration;
        amountMinted = ta.amountMinted;
        totalRented = ta.totalRented;
        TAowner = ta.TAowner;
    }

    /**
     * @dev This function is used to get all available TAs to rent, filtering by null rentee addresses
     **/
    function getAllAvailableTAtoRent()
        external
        view
        override
        returns (TAData[] memory availableTAsData, uint256[] memory totalAvailableToRent)
    {
        availableTAsData = new TAData[](nrTaIDs);

        totalAvailableToRent = new uint256[](nrTaIDs);
        uint256 k;

        for (uint256 i = 1; i <= nrTaIDs; i++) {
            TAData memory ta = taIDtoData[i];
            if (ta.totalRented < ta.amountMinted) {
                availableTAsData[k] = ta;
                totalAvailableToRent[k] = ta.amountMinted - ta.totalRented;
                k++;
            }
        }
    }

    /**
     * @dev This function is used to get all TAs available to rent by the target
     * @param _target the target address to filter
     **/
    function getTargetAvailableToRentTAs(address _target)
        external
        view
        override
        returns (TAData[] memory targetAvailableToRentTAs, uint256[] memory totalAvailableToRent)
    {
        uint256 nrAvailToRent = 0;
        if (nrTaIDs > rentedTAs[_target].length) {
            nrAvailToRent = nrTaIDs - rentedTAs[_target].length;
        }

        targetAvailableToRentTAs = new TAData[](nrTaIDs);

        totalAvailableToRent = new uint256[](nrTaIDs);
        uint256 k;

        for (uint256 i = 1; i <= nrTaIDs; i++) {
            TAData memory ta = taIDtoData[i];

            if (!activeRent[_target][ta.taID]) {
                if (ta.totalRented < ta.amountMinted) {
                    targetAvailableToRentTAs[k] = ta;
                    totalAvailableToRent[k] = ta.amountMinted - ta.totalRented;
                    k++;
                }
            }
        }
    }

    /**
     * @dev This function is used to get all active TAs rented by the target
     * @param _target the target address to filter
     **/
    function getTargetActiveRentedTAs(address _target)
        external
        view
        override
        returns (TAData[] memory targetActiveRentedTAsData, uint256[] memory remainingActiveTime)
    {
        uint256[] memory rentedTAIds = rentedTAs[_target];
        uint256 rentedTAsLength = rentedTAIds.length;
        targetActiveRentedTAsData = new TAData[](rentedTAsLength);
        remainingActiveTime = new uint256[](rentedTAsLength);

        uint256 j;
        uint256 currentTimestamp = block.timestamp;
        uint256 taId;

        for (uint256 i = 0; i < rentedTAsLength; i++) {
            taId = rentedTAIds[i];
            if (activeRent[_target][taId] == true) {
                if (!(currentTimestamp > (lastRentingTime[_target][taId] + taIDtoData[taId].rentDuration))) {
                    TAData memory ta = taIDtoData[taId];
                    targetActiveRentedTAsData[j] = ta;
                    remainingActiveTime[j] =
                        lastRentingTime[_target][taId] +
                        taIDtoData[taId].rentDuration -
                        currentTimestamp;
                    j++;
                }
            }
        }
    }

    /**
     * @dev This function is used to get all TAs rented by the target in its lifetime
     * @param _target the target address to filter
     **/
    function getTargetLifetimeRentedTAs(address _target)
        external
        view
        override
        returns (TAData[] memory targetLifetimeRentedTAsData)
    {
        uint256[] memory rentedTAIds = rentedTAs[_target];
        uint256 rentedTAsLength = rentedTAIds.length;
        targetLifetimeRentedTAsData = new TAData[](rentedTAsLength);

        for (uint256 i = 0; i < rentedTAsLength; i++) {
            TAData memory ta = taIDtoData[rentedTAIds[i]];
            targetLifetimeRentedTAsData[i] = ta;
        }
    }

    /**
     * @dev To get the TB pool address
     **/
    function getTBpoolAddress() external view override returns (address payable) {
        return tBpoolAddress;
    }

    /**
     * @dev This function returns the bytes representation of a name
     * @param _taID the id of a TA of choice
     **/
    function getName(uint256 _taID) external view override returns (bytes memory) {
        return bytes(taIDtoData[_taID].name);
    }

    /**
     * @dev This function returns if the rent is active for a given TA
     * @param _target the address of the target rentee
     * @param _taID the id of a TA of choice
     **/
    function getActiveRent(address _target, uint256 _taID) external view override returns (bool) {
        return activeRent[_target][_taID];
    }

    /**
     * @dev This function returns the last renting time for a given ta
     * @param _target the address of the target rentee
     * @param _taID the id of a TA of choice
     **/
    function getLastRentingTime(address _target, uint256 _taID) external view override returns (uint256) {
        return lastRentingTime[_target][_taID];
    }

    /**
     * @dev This function returns the address that minted a certain taID
     * @param _taID the id of a TA of choice
     **/
    function getTAowner(uint256 _taID) external view returns (address payable) {
        return taIDtoData[_taID].TAowner;
    }

    function _sendViaCall(address payable _to, uint256 _value) private {
        (bool sent, ) = _to.call{value: _value}("");
        require(sent, "Failed to send Ether");
    }
}
