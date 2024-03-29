// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Marketplace is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    
    // Create a counter to track the token IDs
    Counters.Counter private _tokenIds;
    
    // Structure to store the details of a token
    struct Token {
        uint256 tokenId;
        address owner;
        uint256 price;
    }
    
    // Mapping to track the token details by the token ID
    mapping(uint256 => Token) private _tokens;
    
    // Event for when a new token is listed for sale
    event TokenListed(uint256 indexed tokenId, address indexed owner, uint256 price);
    
    // Event for when a token is purchased
    event TokenPurchased(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}
    
    // Function to list a token for sale
    function listToken(uint256 _price) public whenNotPaused {
        _tokenIds.increment();
        
        uint256 newTokenId = _tokenIds.current();
        
        // Mint a new token and assign ownership to the caller
        _mint(msg.sender, newTokenId);
        
        // Store token details
        _tokens[newTokenId] = Token(newTokenId, msg.sender, _price);
        
        emit TokenListed(newTokenId, msg.sender, _price);
    }
    
    // Function to purchase a token
    function purchaseToken(uint256 _tokenId) public payable whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        
        Token memory token = _tokens[_tokenId];
        
        // Check if the token is for sale
        require(token.price > 0, "Token is not for sale");
        
        // Check if the purchase amount is equal to the token price
        require(msg.value == token.price, "Incorrect amount");
        
        address seller = token.owner;
        
        // Transfer ownership of the token to the buyer
        _transfer(seller, msg.sender, _tokenId);
        
        // Update token price and owner
        token.price = 0;
        token.owner = msg.sender;
        
        // Update token details in the mapping
        _tokens[_tokenId] = token;
        
        // Send the payment to the seller
        payable(seller).transfer(msg.value);
        
        emit TokenPurchased(_tokenId, msg.sender, seller, msg.value);
    }
    
    // Function to get the details of a token
    function getTokenDetails(uint256 _tokenId) public view returns (Token memory) {
        require(_exists(_tokenId), "Token does not exist");
        
        return _tokens[_tokenId];
    }
    
    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }
    
    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to withdraw the contract balance
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}