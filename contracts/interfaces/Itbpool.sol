// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

/**
 * @title Marketplace interface contract contract
 * @dev Main point of interaction the Marketplace contract
 **/
interface ITBpool {
    struct PoolStaker {
        uint256 amount; // The NFT tokens quantity the user has staked.
        uint256 rewards; // The reward tokens quantity the user can harvest
        uint256 rewardDebt; // The amount relative to accumulatedRewardsPerShare the user can't get as reward
    }

    /**
     * @dev This function is used to stake NFTs in the pool to have access to rewards
     * @param _tbID the id of the TB which will be staked
     * @param _quantity quantity of TB to be staked
     **/
    function stakeNFT(uint256 _tbID, uint256 _quantity) external;

    /**
     * @dev This function is used for the staker to harvest the rewards he is entitled to
     **/
    function harvestRewards() external;

    /**
     * @dev This function is used for the staker to harvest the remaining rewards and unstake all his/her tokens
     * @param _tbID array with the id of the TB which have been staked by the address
     * @param _quantity array with the quantity of each TB that have been staked by the address
     **/
    function withdraw(uint256[] memory _tbID, uint256[] memory _quantity) external;
}
