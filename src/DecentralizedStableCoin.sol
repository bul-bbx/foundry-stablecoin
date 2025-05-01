//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title Decentralized Stable Coin
 * @author Veliko Velikov
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 * This is the contract meant to be governed by DSCEngine. This contract is just the ERC20 implementation of our stablecoin system.
 *
 * @notice This contract implements a decentralized stable coin.
 * @dev The contract is based on the ERC20 standard and includes minting, burning, and transferring functionalities.
 */

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    /**
     * Errors
     */
    error DecentralizedStableCoin__MustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExeedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();

    /**State Variables*/
    /**Events*/

    /** Functions*/
    constructor() ERC20("Decentralized Stable Coin", "DSC") Ownable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266){
        // Additional initialization logic can be added here if needed
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin__BurnAmountExeedsBalance();
        }
        super.burn(_amount);
    }
}
