// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

/*
    NFT Staking
    xxx- Create your own NFT with a max supply of 100
    xxx - Set lock in period
    xxx- Specify an NFT to be allowed for staking. 1 address only
    xxx - Stake method should transfer the NFT from user's wallet to stake contract
    - User should earn .001 eth every block while NFT is staked
    xxx- User should only be allowed to unstake the NFT after the lock-in period
    xxx - ETH rewards accumulation should stop after the user unstaked the NFT
    xxx- User should be able to claim the rewards only after unstaking the NFT
*/

// Simple NFT Token Contract
contract Pokemon is ERC721, Ownable {
    uint public tokenId = 0;
    uint public currentSupply = 0;
    uint public maxSupply = 100;
    uint totalMinted;

    constructor() ERC721("Pokemon", "PKM") {}
    
    function safeMint() public {
        totalMinted = currentSupply;
        require(totalMinted <= maxSupply, "ERC721: minting limit reached");
        _safeMint(msg.sender, totalMinted);
        currentSupply += 1;
    }
}


contract NFTStaker is Ownable{
        
    IERC721 public immutable nftCollection;


    struct StakedToken{
        address staker;
        uint tokenId;
    }
    uint public rewardsPerBlock = 0.001 ether;
    uint public lockPeriod;

    struct StakerInfo{
        uint amountStaked;
        StakedToken[] stakedTokens;
        uint durationOfStake;
        uint unclaimedRewards;
        uint blockNumber;
    }

    mapping(address => StakerInfo) public stakers;
    mapping(uint => address) public stakerAddress;

    constructor(IERC721 _nftCollection ) payable {
        require(address(this).balance > 0, "need to deposit eth");
        nftCollection = _nftCollection;
    }


    function setLockTimePeriod (uint _lockPeriod) external onlyOwner{
        lockPeriod = _lockPeriod;
    }

    function stake(uint256 _tokenId) external {
        if(stakers[msg.sender].amountStaked > 0){
            uint rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }


        require(nftCollection.ownerOf(_tokenId) == msg.sender, "You don't own this token");
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId);

        stakers[msg.sender].stakedTokens.push(stakedToken);
        stakers[msg.sender].amountStaked++;
        stakers[msg.sender].durationOfStake = block.timestamp;
        stakers[msg.sender].blockNumber = block.number;
        stakerAddress[_tokenId] = msg.sender;
    }


    function unStake(uint _tokenId) external {
        require(stakers[msg.sender].amountStaked > 0, " You have no tokens staked yet");
        require(stakerAddress[_tokenId] == msg.sender, " You dont own this token");
        

        //find the index of this token id in the stakedTokens array
        uint index = 0;
        for(uint i = 0; i < stakers[msg.sender].stakedTokens.length; i++){
            if(stakers[msg.sender].stakedTokens[i].tokenId == _tokenId){
                index = i;
                break;
            }
        }
        //remove this token from the stakedtokens array
        stakers[msg.sender].stakedTokens[index].staker = address(0);
        stakers[msg.sender].amountStaked--;
        stakers[msg.sender].durationOfStake = block.timestamp;
        stakers[msg.sender].blockNumber = block.number;

        require(stakers[msg.sender].durationOfStake > lockPeriod, "Stake is still in lock period");

        stakerAddress[_tokenId] = address(0);
        nftCollection.transferFrom(address(this), msg.sender, _tokenId);

    }


    function claimRewards() external{
        uint rewards = calculateRewards(msg.sender) +
        stakers[msg.sender].unclaimedRewards;

        require(rewards > 0, "You have no rewards to claim");
        require(stakers[msg.sender].amountStaked == 0, "You still have NFT staked");


        payable(msg.sender).transfer(rewards);


        stakers[msg.sender].durationOfStake = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;

    }


    function calculateRewards(address _staker) 
    internal
    view 
    returns(uint _rewards)
    {
        return(
           ((block.timestamp - stakers[_staker].durationOfStake) * (block.number - stakers[_staker].blockNumber)
             * rewardsPerBlock)
             );
    }



    function viewRewards(address _staker) 
    public
    view
    returns(uint){
       // require(stakers[msg.sender].amountStaked > 0, "No NFT staked yet to generate rewards");
          uint rewards = calculateRewards(_staker) +
          stakers[_staker].unclaimedRewards;
          return rewards;
    }

    function getStakedTokens(address _staker)
    public
    view
    returns (StakedToken [] memory)
    {
        if(stakers[_staker].amountStaked > 0){

            StakedToken [] memory _stakedTokens = new StakedToken[](stakers[_staker].amountStaked);
            uint _index =0;

            for(uint j =0; j< stakers[_staker].stakedTokens.length; j++){
                if(stakers[_staker].stakedTokens[j].staker != (address(0))){
                    _stakedTokens[_index] = stakers[_staker].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        else{
            return new StakedToken[](0);
        }
    }
    


}