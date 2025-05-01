//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {Vm} from "forge-std/Vm.sol";

contract Handler is Test {
    DSCEngine engine;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 public timesMintIsCalled;
    address[] public userWithCollateral;
    MockV3Aggregator public ethUsdPriceFeed;

    uint256 MAX_DEPOSIT_SIZE = type(uint256).max;

    constructor(DSCEngine _engine, DecentralizedStableCoin _dsc) {
        engine = _engine;
        dsc = _dsc;

        address[] memory collateralTokes = engine.getCollateralTokens();
        weth = ERC20Mock(collateralTokes[0]);
        wbtc = ERC20Mock(collateralTokes[1]);

        ethUsdPriceFeed = MockV3Aggregator(
            engine.getCollateralTokenPriceFeed(address(weth))
        );
    }

    // function updateCollateralPrice(uint96 newPrice) public {
    //     int256 newPriceInt = int256(uint256(newPrice));
    //     ethUsdPriceFeed.updateAnswer(newPriceInt);
    // }

    function depositCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 0, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(engine), amountCollateral);
        engine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        userWithCollateral.push(msg.sender);
    }

    function redeemCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);

        uint256 maxCollateralToRedeem = engine.getCollateralBalanceOfUser(
            msg.sender,
            address(collateral)
        );
        vm.assume(maxCollateralToRedeem > 0);
        amountCollateral = bound(amountCollateral, 1, maxCollateralToRedeem);

        vm.startPrank(msg.sender);
        engine.redeemCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        if (userWithCollateral.length == 0) {
            return;
        }
        address sender = userWithCollateral[
            addressSeed % userWithCollateral.length
        ];
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine
            .getAccountInformation(sender);
        int256 maxDscToMin = (int256(collateralValueInUsd) / 2) -
            int256(totalDscMinted);
        if (maxDscToMin < 0) {
            return;
        }
        amount = bound(amount, 0, uint256(maxDscToMin));
        if (amount == 0) {
            return;
        }
        vm.startPrank(sender);
        engine.mintDsc(amount);
        vm.stopPrank();
    }

    /** Helper Functions */

    function _getCollateralFromSeed(
        uint256 collateralSeed
    ) public view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}
