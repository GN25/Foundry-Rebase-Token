//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Rebase Token
 * @author Guillem Navarra (GN25)
 * @notice This is a cross-chain rebase token that incentivises users to deposit
 * into a vault and gain interest.
 * @notice The interest in the smart contract can only decrease
 * @notice Each user will have its own interest rate (the global interest rate in the moment of the deposit)
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 actualInterest, uint256 newInterest);

    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");

    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;
    mapping(address => uint256) public s_userInterestRate;
    mapping(address => uint256) public s_userlastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    /**
     *
     * @param _to the user that we want to set as a minter and burner
     * @notice the owner could grant himself this role, making this contract more centralized. This is a known problem.
     */
    function grantMintAndBurnRole(address _to) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _to);
    }

    /**
     *
     * @param _newInterestRate The new interest rate
     * @notice this sets a new interest rate that must always be lower than the previous
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate >= s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        } else {
            s_interestRate = _newInterestRate;
            emit InterestRateSet(_newInterestRate);
        }
    }

    /**
     *
     * @param _to the user to mint tokens to
     * @param _amount the amount of tokens to be minted
     */
    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    /**
     *
     * @param _from the user to burn tokens from
     * @param _amount the amount of tokens to be burnt
     * @notice this will burn the user's tokens when they withdraw from the vault
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     *
     * @param _user the user to calculate the balance for
     * @notice this calculates the balance for a user as the sum of the minted tokens + the interest
     * gained from the user's interest rate
     * @return The balance of the user calculated as stated above
     */
    function balanceOf(address _user) public view override returns (uint256) {
        return (super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user)) / PRECISION_FACTOR;
    }

    /**
     *
     * @param _recipient the user to send tokens to
     * @param _amount the amount of tokens to be sent
     * @notice transfers tokens from a user to another
     * @notice a user could set a wallet in the begining and mint a few tokens in order to get the higher
     * interest rate later with another account. This is a known bug.
     * @return True if the transaction was a success
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }

        return super.transfer(_recipient, _amount);
    }

    /**
     *
     * @param _sender the user who sends tokens
     * @param _recipient the recipient of the tokens
     * @param _amount the amount of tokens to be sent
     * @notice transfers tokens from a user to another
     * @return True if the transaction was a success
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }

        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     *
     * @param _user the user whos balance we want to know
     * @return amount the amount of tokens that have been minted
     * @notice this function returns ONLY the minted tokens to a user.
     */
    function principleBalanceOf(address _user) public view returns (uint256 amount) {
        amount = super.balanceOf(_user);
    }

    /**
     *
     * @param _user the user whos accumulated interest wants to be calculated
     * @return linearInterest The accumulated iterest accumulated since the last update
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user)
        internal
        view
        returns (uint256 linearInterest)
    {
        uint256 timeElapsed = block.timestamp - s_userlastUpdatedTimestamp[_user];
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed);
    }

    /**
     *
     * @param _user the user to mint the accrued interest to
     * @notice this only mints the accrued interest in order to avoid people depositing a small ammount
     * to later benefit from the high interest rates
     */
    function _mintAccruedInterest(address _user) internal {
        uint256 previousPrincipleBalance = super.balanceOf(_user);
        uint256 currentBalance = balanceOf(_user);
        uint256 balanceIncreae = currentBalance - previousPrincipleBalance;
        s_userlastUpdatedTimestamp[_user] = block.timestamp;
        _mint(_user, balanceIncreae);
    }

    /**
     *
     * @param user  user to know its interest rate
     * @notice this returns a uint256 corresponding to the interest rate of a user
     */
    function getUserInterestRate(address user) external view returns (uint256) {
        return s_userInterestRate[user];
    }

    /**
     * @return the interest rate in the moment the funcion is called
     * @notice this is a funcion that could be used to get the interest rate currently in the contract
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }
}
