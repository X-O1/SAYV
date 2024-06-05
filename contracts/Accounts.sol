// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Account managment for SAYV: An on-chain high yield savings account
 * @dev This contract creates accounts, tracks balances and sets up account inheritance
 */
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPool} from "lib/aave-address-book/lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract Accounts is ReentrancyGuard {
    event Account_Deposit(address indexed user, address indexed token, uint256 indexed amount);
    event Earn_Deposit(address indexed user, address indexed token, uint256 indexed amount);

    address private constant USDC_ADDRESS = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address private constant USDT_ADDRESS = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
    address private constant DAI_ADDRESS = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
    address private constant AUSDC_ADDRESS = 0x16dA4541aD1807f4443d92D26044C1147406EB80;
    address private constant AUSDT_ADDRESS = 0xAF0F6e8b0Dc5c913bbF4d14c22B4E78Dd14310B6;
    address private constant ADAI_ADDRESS = 0x29598b72eb5CeBd806C5dCD549490FdA35B13cD8;
    address[] private WHITELISTED_TOKENS = [USDC_ADDRESS, USDT_ADDRESS, DAI_ADDRESS];

    mapping(address user => mapping(address token => uint256 amount)) private s_accountBalance;
    mapping(address user => mapping(address token => uint256 amount)) private s_earnBalance;
    mapping(address user => address[] beneficiaries) private s_accountBeneficiaries;

    function deposit(address token, uint256 amount) public nonReentrant {
        require(_checkTokenWhitelist(token), "Token not whitelisted");
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Amount not approved");

        s_accountBalance[msg.sender][token] += amount;

        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Deposit failed");
        emit Accont_Deposit(msg.sender, token, amount);
    }

    function _checkTokenWhitelist(address token) internal view returns (bool) {
        for (uint256 i = 0; i < WHITELISTED_TOKENS.length; i++) {
            if (token == WHITELISTED_TOKENS[i]) {
                return true;
            }
        }
        return false;
    }

    function earn(address token, uint256 amount) public nonReentrant {
        require(_getAccountBalance(msg.sender, token) >= amount, "Insufficient Funds");

        s_accountBalance[msg.sender][token] -= amount;
        s_earnBalance[msg.sender][token] += amount;

        IPool.supply(token, amount, address(this), 0);

        emit Earn_Deposit(msg.sender, token, amount);
    }

    function _getAccountBalance(address user, address token) public view returns (uint256) {
        return s_accountBalance[user][token];
    }

    function _getEarnBalance(address user, address token) public view returns (uint256) {
        return s_earnBalance[user][token];
    }
}
