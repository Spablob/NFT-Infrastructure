// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ITB} from "./interfaces/Itb.sol";
import {TA} from "./TA.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TB ERC1155 contract
 * @dev Used to mint TB
 **/
contract TB is ERC1155, Ownable, ITB {
    //===============Variables=============

    TA TAcontract;
    address payable tBpoolAddress;
    address payable marketplaceAddress;
    bool defineInstances;
    uint256 nrTbIDs;

    mapping(uint256 => TBData) tbIDtoData; // stores TBData relative to each TB id
    mapping(bytes => bool) registeredCIDsTB; // stores whether a CID has already been registered
    mapping(bytes => bool) registeredNamesTB; // stores whether a name has already been registered
    mapping(address => uint256[]) public mintedTBs; // stores all the TB ids an address has minted
    mapping(address => mapping(uint256 => bool)) public hasMinted;

    uint256[] availableTBsToMint;

    //===============Functions=============
    constructor(address _TAaddress) ERC1155("") {
        require(_TAaddress != address(0));
        TAcontract = TA(_TAaddress);
    }

    /**
     * @dev This function defines TB pool address
     * @notice this function should check that only the owner can call it
     * @param _tBpoolAddress address of TB pool
     **/
    function setInstances(address payable _tBpoolAddress, address payable _marketplaceAddress)
        external
        override
        onlyOwner
    {
        require(_tBpoolAddress != address(0));
        require(_marketplaceAddress != address(0));
        tBpoolAddress = _tBpoolAddress;
        marketplaceAddress = _marketplaceAddress;
    }

    /**
     * @dev This function is used to enable the minting of new TBs by marketplace participants
     * @notice this function can only be called by Rentees. If the TA Owner wants to enable a mint he must rent to himself first
     * @param _taID the ID of the corresponding TA from which the metadata will be merged
     * @param _nameTB  name of the TB token
     * @param _metadataCID The IPFS link to the merged metadata (TA + TB) - perform merge with NFT.storage first
     * @param _mintPrice Desired minting price
     * @param _royaltyPercentage % desired resale royalty
     **/
    function enableTBMint(
        uint256 _taID,
        string memory _nameTB,
        string memory _metadataCID,
        uint256 _mintPrice,
        uint256 _royaltyPercentage
    ) external override {
        require(TAcontract.checkIfTAisActive(_taID, msg.sender) == true, "This address is not renting this TA id");
        require(
            _containWord(TAcontract.getName(_taID), bytes(_nameTB)) == true,
            "TA name must be contained in TB name"
        );
        require(registeredNamesTB[bytes(_nameTB)] == false, "Each name can only be minted once");
        require(registeredCIDsTB[bytes(_metadataCID)] == false, "Each metadataLink can only be minted once");
        require(_royaltyPercentage < 9500 && _royaltyPercentage > 0, "Invalid royalty %");

        nrTbIDs++;
        tbIDtoData[nrTbIDs] = TBData(
            nrTbIDs,
            _taID,
            _mintPrice,
            _royaltyPercentage,
            0,
            _nameTB,
            _metadataCID,
            false,
            true,
            payable(msg.sender)
        );

        registeredNamesTB[bytes(_nameTB)] = true;
        registeredCIDsTB[bytes(_metadataCID)] = true;
    }

    /**
     * @dev This function is used to mint TBs off a selected TA. TB Minting must be enabled
     * @param _tbID the id of the TB whose enabled TB will be minted
     * @param _quantity the quantity of TB to mint
     **/
    function mintTB(uint256 _tbID, uint256 _quantity) external payable override {
        TBData memory tb = tbIDtoData[_tbID];

        require(TAcontract.checkIfTAisActive(tb.taID, tb.TBowner) == true, "TA license has expired");
        require(tb.mintPrice * _quantity == msg.value, "Not enough ETH was sent");

        if (!hasMinted[msg.sender][_tbID]) {
            mintedTBs[msg.sender].push(_tbID);
            hasMinted[msg.sender][_tbID] = true;
        }

        _sendViaCall(tb.TBowner, (msg.value * 8000) / 10000); // 80% to TB enabler
        _sendViaCall(TAcontract.getTAowner(tb.taID), (msg.value * 1000) / 10000); // 10% to TA owner
        _sendViaCall(tBpoolAddress, (msg.value * 1000) / 10000); // The last 10% to TB holders remain in this contract

        _mint(msg.sender, _tbID, _quantity, "");
    }

    /**
     * @dev This function returns the taID from which a certain tbID originates
     * @param _tbID the id of a TB of choice
     **/
    function getTAid(uint256 _tbID) external view override returns (uint256) {
        return tbIDtoData[_tbID].taID;
    }

    /**
     * @dev This function is to get all the data of a given TB
     * @param _tbID the target TB
     **/
    function getTB(uint256 _tbID)
        external
        view
        override
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
        )
    {
        TBData memory tb = tbIDtoData[_tbID];

        taID = tb.taID;
        mintPrice = tb.mintPrice;
        royaltyPercentage = tb.royaltyPercentage;
        salePrice = tb.salePrice;
        name = tb.name;
        metadataCID = tb.metadataCID;
        markedForSale = tb.markedForSale;
        mintEnabled = tb.mintEnabled;
        TBowner = tb.TBowner;
    }

    /**
     * @dev This function returns the address that minted a certain tbID
     * @param _tbID the id of a TB of choice
     **/
    function getTBowner(uint256 _tbID) external view override returns (address payable) {
        return tbIDtoData[_tbID].TBowner;
    }

    /**
     * @dev This function returns the % that minter defined as royalty given a certain tbID
     * @param _tbID the id of a TB of choice
     **/
    function getRoyaltyPercentage(uint256 _tbID) external view override returns (uint256) {
        return tbIDtoData[_tbID].royaltyPercentage;
    }

    /**
     * @dev This function is used to get all TBs available to mint
     **/
    function getAllAvailableTBsToMint()
        external
        view
        override
        returns (TBData[] memory allAvailableTBsToMint, uint256[] memory remainingActiveTime)
    {
        allAvailableTBsToMint = new TBData[](nrTbIDs);
        remainingActiveTime = new uint256[](nrTbIDs);

        uint256 j = 0;
        uint256 currentTimestamp = block.timestamp;
        for (uint256 i = 1; i <= nrTbIDs; i++) {
            TBData memory tb = tbIDtoData[i];
            if (tb.mintEnabled && TAcontract.getActiveRent(tb.TBowner, tb.taID) == true) {
                (, , , , uint256 rentDuration, , , ) = TAcontract.getTA(tb.taID);
                uint256 lastRentingTime = TAcontract.getLastRentingTime(tb.TBowner, tb.taID);
                if (!(currentTimestamp > (lastRentingTime + rentDuration))) {
                    allAvailableTBsToMint[j] = tb;
                    remainingActiveTime[j] = lastRentingTime + rentDuration - currentTimestamp;
                    j++;
                }
            }
        }
    }

    /**
     * @dev This function is used to get all TBs that an address has minted since ever
     * @param _target the address to target
     **/
    function getLifetimeMintedTBs(address _target)
        external
        view
        override
        returns (
            TBData[] memory targetMintedTbs,
            uint256[] memory quantity,
            uint256[] memory remainingActiveTime
        )
    {
        uint256[] memory mintedTBIds = mintedTBs[_target];
        uint256 nrTBsMinted = mintedTBIds.length;
        targetMintedTbs = new TBData[](nrTBsMinted);
        quantity = new uint256[](nrTBsMinted);
        remainingActiveTime = new uint256[](nrTBsMinted);

        uint256 tbId;
        uint256 currentTimestamp = block.timestamp;

        for (uint256 i = 0; i < nrTBsMinted; i++) {
            tbId = mintedTBIds[i];
            TBData memory tb = tbIDtoData[tbId];
            targetMintedTbs[i] = tb;

            quantity[i] = balanceOf(_target, tbId);
            (, , , , uint256 rentDuration, , , ) = TAcontract.getTA(tb.taID);
            uint256 lastRentingTime = TAcontract.getLastRentingTime(tb.TBowner, tb.taID);
            remainingActiveTime[i] = 0;
            if (lastRentingTime + rentDuration > currentTimestamp) {
                remainingActiveTime[i] = lastRentingTime + rentDuration - currentTimestamp;
            }
        }
    }

    /**
     * @dev Returns the TB pool address
     **/
    function getTBpoolAddress() external view returns (address payable) {
        return tBpoolAddress;
    }

    /**
     * @dev Returns if the address has minted or bought a particular token TB
     * @param _target the address to target
     * @param _tbID the target TB
     **/
    function getHasMinted(address _target, uint256 _tbID) external view returns (bool) {
        return hasMinted[_target][_tbID];
    }

    /**
     * @dev Updates with new purchases made
     * @param _target the address to target
     * @param _tbID the target TB
     **/
    function updateHasMintedOrOwned(address _target, uint256 _tbID) external {
        require(msg.sender == marketplaceAddress, "Address not allowed to call this function");
        mintedTBs[_target].push(_tbID);
        hasMinted[_target][_tbID] = true;
    }

    /**
     * @dev Returns true if name is registered, false otherwise
     * @param _name the name to check
     **/
    function isRegisteredName(string memory _name) external view override returns (bool) {
        return registeredNamesTB[bytes(_name)];
    }

    /**
     * @dev Returns true if cid is registered, false otherwise
     * @param _cid the cid to check
     **/
    function isRegisteredMetadata(string memory _cid) external view override returns (bool) {
        return registeredCIDsTB[bytes(_cid)];
    }

    function _containWord(bytes memory whatBytes, bytes memory whereBytes) internal pure returns (bool found) {
        if (whereBytes.length < whatBytes.length) {
            return false;
        }

        found = false;
        for (uint256 i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint256 j = 0; j < whatBytes.length; j++)
                if (whereBytes[i + j] != whatBytes[j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        return found;
    }

    function _sendViaCall(address payable _to, uint256 _value) private {
        (bool sent, ) = _to.call{value: _value}("");
        require(sent, "Failed to send Ether");
    }
}
