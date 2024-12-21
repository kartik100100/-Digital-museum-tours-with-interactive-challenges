// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Digital Museum Tours with Interactive Challenges
/// @notice Allows users to join museum tours, participate in challenges, and earn rewards.
/// @dev Simplified to allow deployment without initial funding for testing purposes.

contract DigitalMuseumTours {
    // Struct to represent a museum tour
    struct Tour {
        string name;
        string challengeQuestion;
        bytes32 correctAnswerHash; // Hash of the correct answer
        uint256 reward; // Reward in wei
        bool isActive;
    }

    // Mapping of tour ID to Tour details
    mapping(uint256 => Tour) public tours;

    // Mapping to track user completions
    mapping(address => mapping(uint256 => bool)) public userCompletedTours;

    uint256 public nextTourId; // Auto-incrementing tour ID
    address public immutable owner; // Contract owner

    // Events
    event TourCreated(uint256 tourId, string name, uint256 reward);
    event ChallengeCompleted(address indexed user, uint256 tourId);

    // Modifier to restrict certain functions to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender; // Set contract deployer as the owner
    }

    /// @notice Creates a new museum tour with a challenge
    /// @param name Name of the tour
    /// @param challengeQuestion The question for the challenge
    /// @param correctAnswer The correct answer (hashed for security)
    /// @param reward The reward amount in wei
    function createTour(
        string memory name,
        string memory challengeQuestion,
        string memory correctAnswer,
        uint256 reward
    ) public onlyOwner {
        require(reward <= address(this).balance, "Not enough funds for this reward");

        tours[nextTourId] = Tour({
            name: name,
            challengeQuestion: challengeQuestion,
            correctAnswerHash: keccak256(abi.encodePacked(correctAnswer)),
            reward: reward,
            isActive: true
        });

        emit TourCreated(nextTourId, name, reward);
        nextTourId++;
    }

    /// @notice Joins a museum tour and retrieves the challenge question
    /// @param tourId The ID of the tour to join
    /// @return The challenge question
    function joinTour(uint256 tourId) public view returns (string memory) {
        Tour storage tour = tours[tourId];
        require(tour.isActive, "Tour is not active");
        return tour.challengeQuestion;
    }

    /// @notice Completes a challenge by providing the correct answer
    /// @param tourId The ID of the tour
    /// @param answer The user's answer to the challenge
    function completeChallenge(uint256 tourId, string memory answer) public {
        Tour storage tour = tours[tourId];
        require(tour.isActive, "Tour is not active");
        require(!userCompletedTours[msg.sender][tourId], "Challenge already completed");
        require(
            keccak256(abi.encodePacked(answer)) == tour.correctAnswerHash,
            "Incorrect answer"
        );

        userCompletedTours[msg.sender][tourId] = true;

        uint256 reward = tour.reward;
        require(reward <= address(this).balance, "Insufficient funds");

        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Reward transfer failed");

        emit ChallengeCompleted(msg.sender, tourId);
    }

    /// @notice Adds funds to the contract for rewards
    function addFunds() public payable onlyOwner {
        // Funds are directly added to the contract balance
    }

    /// @notice Withdraws funds from the contract
    /// @param amount The amount to withdraw in wei
    function withdrawFunds(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Not enough funds");

        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Withdrawal failed");
    }

    /// @notice Fetches details of a specific tour
    /// @param tourId The ID of the tour
    /// @return name Name of the tour
    /// @return challengeQuestion The challenge question
    /// @return reward The reward amount in wei
    /// @return isActive Whether the tour is active
    function getTourDetails(uint256 tourId)
        public
        view
        returns (string memory name, string memory challengeQuestion, uint256 reward, bool isActive)
    {
        Tour storage tour = tours[tourId];
        return (tour.name, tour.challengeQuestion, tour.reward, tour.isActive);
    }

    /// @notice Fetches the IDs of completed tours for a user
    /// @param user The address of the user
    /// @return completedTourIds Array of completed tour IDs
    function getUserCompletedTours(address user) public view returns (uint256[] memory) {
        uint256[] memory completedTourIds = new uint256[](nextTourId);
        uint256 count = 0;

        for (uint256 i = 0; i < nextTourId; i++) {
            if (userCompletedTours[user][i]) {
                completedTourIds[count] = i;
                count++;
            }
        }

        // Resize the array to fit the count
        assembly {
            mstore(completedTourIds, count)
        }

        return completedTourIds;
    }
}
