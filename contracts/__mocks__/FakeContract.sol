pragma solidity >=0.8.4 <0.9.0;

import "../ERC20ScalableReward.sol";

contract FakeContract is ERC20ScalableReward {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokensPerBlock,
        uint256 _blockFreezeInterval
    )
        ERC20ScalableReward(
            _tokenName,
            _tokenSymbol,
            _tokensPerBlock,
            _blockFreezeInterval
        )
    {}
}
