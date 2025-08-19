// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 * @title RebaseToken
 * @author Pandit Dhamdhere
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in rewards.
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each will user will have their own interest rate that is the global interest rate at the time of depositing.
 */
contract RebaseToken is ERC20 {
    /////////////////////////////////////////////
    ////////////////// ERRORS ///////////////////
    /////////////////////////////////////////////
    error RebaseToken__InterestRateOnlyDecrease(
        uint256 oldInterestRate,
        uint256 newInterestRate
    );

    /////////////////////////////////////////////
    ////////////// STATE VARIABLES //////////////
    /////////////////////////////////////////////
    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = 5e18;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    /////////////////////////////////////////////
    ////////////////// EVENTS ///////////////////
    /////////////////////////////////////////////

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") {}

    function setInteresRate(uint256 _newInterestRate) external {
        if (_newInterestRate < s_interestRate) {
            revert RebaseToken__InterestRateOnlyDecrease(
                s_interestRate,
                _newInterestRate
            );
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

    function balanceOf(address _user) public view override returns (uint256) {
        return
            (super.balanceOf(_user) *
                _calculateUserAccumulatedInterestSinceLastUpdate(_user)) /
            PRECISION_FACTOR;
    }

    /////////////////////////////////////////////////
    //////////////  INTERNAL FUNCTIONS /////////////
    /////////////////////////////////////////////////

    function _mintAccruedInterest(address _user) internal {
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(
        address _user
    ) internal view returns (uint256 linearInterest) {
        uint256 timeElapsed = block.timestamp -
            s_userLastUpdatedTimestamp[_user];
        linearInterest = (PRECISION_FACTOR +
            (s_userInterestRate[_user] * timeElapsed));
    }
}
