//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "../interface";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Abitrage is Ownable {

  address [] public routers;
  address [] public tokens;
  address [] public stables;

  function addRouters(address[] calldata _routers) external onlyOwner {
    for (uint i=0; i<_routers.length; i++) {
      routers.push(_routers[i]);
    }
  }


  function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
    IERC20(_tokenIn).approve(router, _amount);
    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    uint deadline = block.timestamp + 300;
    IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
  }

  function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256 _result) {
    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    unit[] memory amountOutMins =  IUniswapV2Router(router).getAmountsOut(_amount, path);
     _result = amountOutMins[path.length -1];
  
  }
//   get profitable trade
  function getTradeEstimate(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external view returns (uint256) {
    uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
    uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
    return amtBack2;
  }
//   Batch dex swap
  function dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external onlyOwner {
    uint startBalance = IERC20(_token1).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    swap(_router1,_token1, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount = token2Balance - token2InitialBalance;
    swap(_router2,_token2, _token1,tradeableAmount);
    uint endBalance = IERC20(_token1).balanceOf(address(this));
    require(endBalance > startBalance, "Trade Reverted, No Profit Made");
  }

 
}