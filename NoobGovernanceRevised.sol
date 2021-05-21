// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./safemath.sol"; //use safemath to prevent overflow

contract NoobGovernance is Ownable{
    
  using SafeMath for uint256;
  using SafeMath16 for uint16;

  uint public startTimestamp;
  uint public duration;
  uint public voteEventId;
  string public winner;
  bool public voteEventStatus;
  
  /**
     * @dev use struct with 2 consecutive uin16 variables to reduce storage space required
     * maximum of 65535 candidates
  */
  struct candidates { 
      string name;
      uint16 id; 
      uint16 votes;
  }
  
  candidates[] public candidateList;
  mapping(address => uint) public voterList;

  event VoteRegistered(string _candidate);
  event VoteFinalized(string _winner);
  
  /**
     * @dev intialize constructor with the voting event duration as an argument
  */ 
  constructor(uint _duration) public {
    startTimestamp = block.timestamp;
    duration = _duration;
    voteEventId = voteEventId.add(1);
    voteEventStatus = false;
  }
  
  /**
     * @dev cannot be the owner
  */
  modifier notOwner() {
      require(owner() != msg.sender, "Owner cannot cheat"); 
      _;
    }
    
  /**
     * @dev check if current voting event has been finalized
  */  
  modifier voteEventFinalized() {
      require(voteEventStatus == true, "Event is still in process"); 
      _;
    }
  
   /**
     * @dev check if time has passed duration
  */  
  modifier exceedDuration() {
      require(block.timestamp > startTimestamp.add(duration), "Vote time has not ended"); 
      _;
    }
    
   /**
     * @dev check if time is within duration
  */    
  modifier withinDuration() {
      require(block.timestamp <= startTimestamp.add(duration), "Vote time has ended"); 
      _;
    }
  
  /**
     * @dev one address can only vote once per voting event
  */      
  modifier voteLimit() {
      require(voterList[msg.sender] != voteEventId, "You can only vote once"); 
      _;
    }
  
  /**
     * @dev number of candidates cannot exceed max value of uint16
  */      
  modifier candidateLimit() {
      require(candidateList.length < 65535, "Candidate limit reached"); 
      _;
    }
  
  /**
     * @dev called by startNewVote to set new duration for the new voting event
  */ 
  function _setDuration(uint _duration) private onlyOwner { 
      duration = _duration;
  }
  
  /**
     * @dev the owner can only start new voting event after finalizing the votes of current event 
     * and the previous event's duration has passed
  */ 
  function startNewVote(uint _duration) external onlyOwner exceedDuration voteEventFinalized { 
      startTimestamp = block.timestamp;
      _setDuration(_duration);
      voteEventId = voteEventId.add(1);
      voteEventStatus = false;
      delete candidateList;
  }
  
  /**
     * @dev candidate id will always equal to index of candidateList
  */ 
  function addCandidate(string memory _name) external onlyOwner candidateLimit {
      candidateList.push(candidates(_name, uint16(candidateList.length), uint16(0))); 
  }
  
  /**
     * @dev the owner of the contract cannot vote, maximum votes each candidate can get is max value of uint16
  */ 
  function vote(uint16 _id) external withinDuration voteLimit notOwner {
      require(candidateList[_id].votes < 65535, "Vote count has reached limit");
      candidateList[_id].votes = candidateList[_id].votes.add(1);
      voterList[msg.sender] = voteEventId;
      emit VoteRegistered(candidateList[_id].name);
  }
  
  /**
     * @dev finalize the result of each voting event 
  */ 
  function finalize() public onlyOwner exceedDuration {
      string memory winnerName;
      uint16 latestWinner = candidateList[uint16(0)].id;
      
      for (uint16 i = latestWinner + 1; i < candidateList.length; i++) { 
          if (candidateList[i].votes > candidateList[latestWinner].votes) {
              latestWinner = i;
              winnerName = candidateList[i].name;
          } else if (candidateList[i].votes == candidateList[latestWinner].votes) {
            winnerName = "No Winner";
            }
      }
       voteEventStatus = true;
       winner = winnerName;
       emit VoteFinalized(winner);
    
  }
}
