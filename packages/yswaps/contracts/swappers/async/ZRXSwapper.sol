// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './AsyncSwapper.sol';

interface IZRXSwapper is IAsyncSwapper {
  error TradeReverted();

  // solhint-disable-next-line func-name-mixedcase
  function ZRX() external view returns (address);
}

contract ZRXSwapper is IZRXSwapper, AsyncSwapper {
  using SafeERC20 for IERC20;

  // solhint-disable-next-line var-name-mixedcase
  address public immutable override ZRX;

  constructor(
    address _governor,
    address _tradeFactory,
    // solhint-disable-next-line var-name-mixedcase
    address _ZRX
  ) AsyncSwapper(_governor, _tradeFactory) {
    ZRX = _ZRX;
  }

  function _executeSwap(
    address _receiver,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    bytes calldata _data
  ) internal override returns (uint256 _receivedAmount) {
    uint256 _initialBalanceTokenIn = IERC20(_tokenIn).balanceOf(address(this));
    uint256 _initialBalanceOfTokenOut = IERC20(_tokenOut).balanceOf(address(this));
    IERC20(_tokenIn).approve(ZRX, 0);
    IERC20(_tokenIn).approve(ZRX, _amountIn);
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = ZRX.call{value: 0}(_data);
    if (!success) revert TradeReverted();
    // Check that token in & amount in was correct
    if (_initialBalanceTokenIn - IERC20(_tokenIn).balanceOf(address(this)) < _amountIn) revert CommonErrors.IncorrectSwapInformation();
    // Check that token out was correct
    uint256 _finalBalanceOfTokenOut = IERC20(_tokenOut).balanceOf(address(this));
    _receivedAmount = _finalBalanceOfTokenOut - _initialBalanceOfTokenOut;
    if (_receivedAmount == 0) revert CommonErrors.IncorrectSwapInformation();
    IERC20(_tokenOut).safeTransfer(_receiver, _receivedAmount);
  }
}
