// TODO: TBD
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error UnauthorizedMinter();
error NoRewards();

abstract contract ERC20ScalableReward is ERC20 {
    uint256 internal roundMask;
    uint256 internal lastMintedBlockNumber;
    uint256 internal totalParticipants;
    uint256 internal immutable blockFreezeInterval;
    uint256 internal immutable tokensPerBlock;
    address internal immutable tokenAddress;

    mapping(address => uint256) internal participantMask;
    mapping(address => bool) internal minters;

    function getRoundMask() external view returns (uint256) {
        return roundMask;
    }

    function getLastMintedBlockNumber() external view returns (uint256) {
        return lastMintedBlockNumber;
    }

    function getTotalParticipants() external view returns (uint256) {
        return totalParticipants;
    }

    function getTokensPerBlock() external view returns (uint256) {
        return tokensPerBlock;
    }

    function getBlockFreezeInterval() external view returns (uint256) {
        return blockFreezeInterval;
    }

    function getParticipantMask() external view returns (uint256) {
        return participantMask[msg.sender];
    }

    /**
     * @dev constructor, initializes variables.
     * @param _tokensPerBlock The amount of token that will be released per block, entered in wei format (E.g. 1000000000000000000)
     * @param _blockFreezeInterval The amount of blocks that need to pass (E.g. 1, 10, 100) before more tokens are brought into the ecosystem.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokensPerBlock,
        uint256 _blockFreezeInterval
    ) ERC20(_tokenName, _tokenSymbol) {
        tokensPerBlock = _tokensPerBlock;
        blockFreezeInterval = _blockFreezeInterval;
        tokenAddress = address(this);
        lastMintedBlockNumber = block.number;
        totalParticipants = 0;
    }

    /**
     * @dev Modifier to check if msg.sender is whitelisted as a minter.
     */
    modifier isAuthorized() {
        if (!minters[msg.sender]) revert UnauthorizedMinter();
        _;
    }

    /**
     * @dev Function to add participants in the network.
     * @param _minter The address that will be able to mint tokens.
     */
    function addMinters(address _minter) external {
        minters[_minter] = true;

        unchecked {
            totalParticipants = totalParticipants + 1;
        }
        updateParticipantMask(_minter);
    }

    /**
     * @dev Function to remove participants in the network.
     * @param _minter The address that will be unable to mint tokens.
     */
    function removeMinters(address _minter) external {
        unchecked {
            totalParticipants = totalParticipants + 1;
        }

        minters[_minter] = false;
    }

    /**
     * @dev Function to introduce new tokens in the network.
     * @return A boolean that indicates if the operation was successful.
     */
    function trigger() external isAuthorized returns (bool) {
        bool res = readyToMint();
        if (res == true) mintTokens();
        return res;
    }

    /**
     * @dev Function to withdraw rewarded tokens by a participant.
     * @return A boolean that indicates if the operation was successful.
     */
    function withdraw() external isAuthorized returns (bool) {
        uint256 rewards = calculateRewards();

        // TODO: Should be done after the update?
        if (rewards == 0) revert NoRewards();

        updateParticipantMask(msg.sender);

        return ERC20(tokenAddress).transfer(msg.sender, rewards);
    }

    function calculateRewards() internal view virtual returns (uint256) {
        uint256 playerMask = participantMask[msg.sender];
        return roundMask - playerMask;
    }

    /**
     * @dev Function to check if new tokens are ready to be minted.
     * @return A boolean that indicates if the operation was successful.
     */
    function readyToMint() public view virtual returns (bool) {
        uint256 currentBlockNumber = block.number;
        uint256 lastBlockNumber = lastMintedBlockNumber;

        return currentBlockNumber > (lastBlockNumber + blockFreezeInterval);
    }

    /**
     * @dev Function to mint new tokens into the economy.
     */
    function mintTokens() private {
        uint256 currentBlockNumber = block.number;
        uint256 tokenReleaseAmount = (currentBlockNumber -
            lastMintedBlockNumber) * tokensPerBlock;

        lastMintedBlockNumber = currentBlockNumber;
        _mint(tokenAddress, tokenReleaseAmount);
        calculateTPP(tokenReleaseAmount);
    }

    /**
     * @dev Function to calculate TPP (token amount per participant).
     */
    function calculateTPP(uint256 tokens) private {
        updateRoundMask(tokens / totalParticipants);
    }

    /**
     * @dev Function to update round mask.
     */
    function updateRoundMask(uint256 tokenPerParticipant) private {
        roundMask = roundMask + tokenPerParticipant;
    }

    /**
     * @dev Function to update participant mask (store the previous round mask)
     */
    function updateParticipantMask(address participant) private {
        uint256 previousRoundMask = roundMask;
        participantMask[participant] = previousRoundMask;
    }
}
