pragma solidity ^0.4.24;

/**
 * Utility library of inline functions on addresses
 */
library Address {

	/**
	 * Returns whether the target address is a contract
	 * @dev This function will return false if invoked during the constructor of a contract,
	 * as the code is not actually created until after the constructor finishes.
	 * @param account address of the account to check
	 * @return whether the target address is a contract
	 */
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		// XXX Currently there is no better way to check if there is a contract in an address
		// than to check the size of the code at that address.
		// See https://ethereum.stackexchange.com/a/14016/36603
		// for more details about how this works.
		// TODO Check this again before the Serenity release, because all addresses will be
		// contracts then.
		// solium-disable-next-line security/no-inline-assembly
		assembly { size := extcodesize(account) }
		return size > 0;
	}

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

	/**
	 * @dev Multiplies two numbers, reverts on overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	/**
	 * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); // Solidity only automatically asserts when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	* @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	/**
	* @dev Adds two numbers, reverts on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}

	/**
	* @dev Divides two numbers and returns the remainder (unsigned integer modulo),
	* reverts when dividing by zero.
		*/
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract IERC721Receiver {
	/**
	* @notice Handle the receipt of an NFT
	* @dev The ERC721 smart contract calls this function on the recipient
	* after a `safeTransfer`. This function MUST return the function selector,
	* otherwise the caller will revert the transaction. The selector to be
	* returned can be obtained as `this.onERC721Received.selector`. This
	* function MAY throw to revert and reject the transfer.
		* Note: the ERC721 contract address is always the message sender.
		* @param operator The address which called `safeTransferFrom` function
	* @param from The address which previously owned the token
	* @param tokenId The NFT identifier which is being transferred
	* @param data Additional data with no specified format
	* @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	*/
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes data
	)
	public
	returns(bytes4);
}

contract IERC721 {

	event Transfer(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);
	event Approval(
		address indexed owner,
		address indexed approved,
		uint256 indexed tokenId
	);
	event ApprovalForAll(
		address indexed owner,
		address indexed operator,
		bool approved
	);

	function balanceOf(address owner) public view returns (uint256 balance);
	function ownerOf(uint256 tokenId) public view returns (address owner);

	function approve(address to, uint256 tokenId) public;
	function getApproved(uint256 tokenId)
	public view returns (address operator);

	function setApprovalForAll(address operator, bool _approved) public;
	function isApprovedForAll(address owner, address operator)
	public view returns (bool);

	function transferFrom(address from, address to, uint256 tokenId) public;
	function safeTransferFrom(address from, address to, uint256 tokenId)
	public;

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes data
	)
	public;
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is IERC721 {

	using SafeMath for uint256;
	using Address for address;

	// Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	// which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

	// Mapping from token ID to owner
	mapping (uint256 => address) private _tokenOwner;

	// Mapping from token ID to approved address
	mapping (uint256 => address) private _tokenApprovals;

	// Mapping from owner to number of owned token
	mapping (address => uint256) private _ownedTokensCount;

	// Mapping from owner to operator approvals
	mapping (address => mapping (address => bool)) private _operatorApprovals;

	bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
	/*
	* 0x80ac58cd ===
	*   bytes4(keccak256('balanceOf(address)')) ^
	*   bytes4(keccak256('ownerOf(uint256)')) ^
	*   bytes4(keccak256('approve(address,uint256)')) ^
	*   bytes4(keccak256('getApproved(uint256)')) ^
	*   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
	*   bytes4(keccak256('isApprovedForAll(address,address)')) ^
	*   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
	*   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
	*   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
	*/

	constructor() public { }

	/**
	* @dev Gets the balance of the specified address
	* @param owner address to query the balance of
	* @return uint256 representing the amount owned by the passed address
	*/
	function balanceOf(address owner) public view returns (uint256) {
		require(owner != address(0));
		return _ownedTokensCount[owner];
	}

	/**
	* @dev Gets the owner of the specified token ID
	* @param tokenId uint256 ID of the token to query the owner of
	* @return owner address currently marked as the owner of the given token ID
	*/
	function ownerOf(uint256 tokenId) public view returns (address) {
		address owner = _tokenOwner[tokenId];
		require(owner != address(0));
		return owner;
	}

	/**
	* @dev Approves another address to transfer the given token ID
	* The zero address indicates there is no approved address.
		* There can only be one approved address per token at a given time.
		* Can only be called by the token owner or an approved operator.
		* @param to address to be approved for the given token ID
	* @param tokenId uint256 ID of the token to be approved
	*/
	function approve(address to, uint256 tokenId) public {
		address owner = ownerOf(tokenId);
		require(to != owner);
		require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

		_tokenApprovals[tokenId] = to;
		emit Approval(owner, to, tokenId);
	}

	/**
	* @dev Gets the approved address for a token ID, or zero if no address set
	* Reverts if the token ID does not exist.
			* @param tokenId uint256 ID of the token to query the approval of
		* @return address currently approved for the given token ID
			*/
	function getApproved(uint256 tokenId) public view returns (address) {
		require(_exists(tokenId));
		return _tokenApprovals[tokenId];
	}

	/**
	* @dev Sets or unsets the approval of a given operator
	* An operator is allowed to transfer all tokens of the sender on their behalf
	* @param to operator address to set the approval
	* @param approved representing the status of the approval to be set
	*/
	function setApprovalForAll(address to, bool approved) public {
		require(to != msg.sender);
		_operatorApprovals[msg.sender][to] = approved;
		emit ApprovalForAll(msg.sender, to, approved);
	}

	/**
	* @dev Tells whether an operator is approved by a given owner
	* @param owner owner address which you want to query the approval of
	* @param operator operator address which you want to query the approval of
	* @return bool whether the given operator is approved by the given owner
	*/
	function isApprovedForAll(
		address owner,
		address operator
	)
	public
	view
	returns (bool)
	{
		return _operatorApprovals[owner][operator];
	}

	/**
	* @dev Transfers the ownership of a given token ID to another address
	* Usage of this method is discouraged, use `safeTransferFrom` whenever possible
	* Requires the msg sender to be the owner, approved, or operator
	* @param from current owner of the token
	* @param to address to receive the ownership of the given token ID
	* @param tokenId uint256 ID of the token to be transferred
	*/
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	)
	public
	{
		require(_isApprovedOrOwner(msg.sender, tokenId));
		require(to != address(0));

		_clearApproval(from, tokenId);
		_removeTokenFrom(from, tokenId);
		_addTokenTo(to, tokenId);

		emit Transfer(from, to, tokenId);
	}

	/**
	* @dev Safely transfers the ownership of a given token ID to another address
	* If the target address is a contract, it must implement `onERC721Received`,
	* which is called upon a safe transfer, and return the magic value
	* `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
	* the transfer is reverted.
		*
		* Requires the msg sender to be the owner, approved, or operator
	* @param from current owner of the token
	* @param to address to receive the ownership of the given token ID
	* @param tokenId uint256 ID of the token to be transferred
	*/
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	)
	public
	{
		// solium-disable-next-line arg-overflow
		safeTransferFrom(from, to, tokenId, "");
	}

	/**
	* @dev Safely transfers the ownership of a given token ID to another address
	* If the target address is a contract, it must implement `onERC721Received`,
	* which is called upon a safe transfer, and return the magic value
	* `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
	* the transfer is reverted.
		* Requires the msg sender to be the owner, approved, or operator
	* @param from current owner of the token
	* @param to address to receive the ownership of the given token ID
	* @param tokenId uint256 ID of the token to be transferred
	* @param _data bytes data to send along with a safe transfer check
	*/
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes _data
	)
	public
	{
		transferFrom(from, to, tokenId);
		// solium-disable-next-line arg-overflow
		require(_checkOnERC721Received(from, to, tokenId, _data));
	}

	/**
	* @dev Returns whether the specified token exists
	* @param tokenId uint256 ID of the token to query the existence of
	* @return whether the token exists
	*/
	function _exists(uint256 tokenId) internal view returns (bool) {
		address owner = _tokenOwner[tokenId];
		return owner != address(0);
	}

	/**
	* @dev Returns whether the given spender can transfer a given token ID
	* @param spender address of the spender to query
	* @param tokenId uint256 ID of the token to be transferred
	* @return bool whether the msg.sender is approved for the given token ID,
		*  is an operator of the owner, or is the owner of the token
	*/
	function _isApprovedOrOwner(
		address spender,
		uint256 tokenId
	)
	internal
	view
	returns (bool)
	{
		address owner = ownerOf(tokenId);
		// Disable solium check because of
		// https://github.com/duaraghav8/Solium/issues/175
		// solium-disable-next-line operator-whitespace
		return (
			spender == owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(owner, spender)
		);
	}

	/**
	* @dev Internal function to mint a new token
	* Reverts if the given token ID already exists
		* @param to The address that will own the minted token
	* @param tokenId uint256 ID of the token to be minted by the msg.sender
	*/
	function _mint(address to, uint256 tokenId) internal {
		require(to != address(0));
		_addTokenTo(to, tokenId);
		emit Transfer(address(0), to, tokenId);
	}

	/**
	* @dev Internal function to burn a specific token
	* Reverts if the token does not exist
		* @param tokenId uint256 ID of the token being burned by the msg.sender
	*/
	function _burn(address owner, uint256 tokenId) internal {
		_clearApproval(owner, tokenId);
		_removeTokenFrom(owner, tokenId);
		emit Transfer(owner, address(0), tokenId);
	}

	/**
	* @dev Internal function to add a token ID to the list of a given address
	* Note that this function is left internal to make ERC721Enumerable possible, but is not
	* intended to be called by custom derived contracts: in particular, it emits no Transfer event.
		* @param to address representing the new owner of the given token ID
	* @param tokenId uint256 ID of the token to be added to the tokens list of the given address
	*/
	function _addTokenTo(address to, uint256 tokenId) internal {
		require(_tokenOwner[tokenId] == address(0));
		_tokenOwner[tokenId] = to;
		_ownedTokensCount[to] = _ownedTokensCount[to].add(1);
	}

	/**
	* @dev Internal function to remove a token ID from the list of a given address
	* Note that this function is left internal to make ERC721Enumerable possible, but is not
	* intended to be called by custom derived contracts: in particular, it emits no Transfer event,
	* and doesn't clear approvals.
	* @param from address representing the previous owner of the given token ID
	* @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
	*/
	function _removeTokenFrom(address from, uint256 tokenId) internal {
		require(ownerOf(tokenId) == from);
		_ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
		_tokenOwner[tokenId] = address(0);
	}

	/**
	* @dev Internal function to invoke `onERC721Received` on a target address
	* The call is not executed if the target address is not a contract
	* @param from address representing the previous owner of the given token ID
	* @param to target address that will receive the tokens
	* @param tokenId uint256 ID of the token to be transferred
	* @param _data bytes optional data to send along with the call
	* @return whether the call correctly returned the expected magic value
	 */
	function _checkOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes _data
	)
	internal
	returns (bool)
	{
		if (!to.isContract()) {
			return true;
		}
		bytes4 retval = IERC721Receiver(to).onERC721Received(
			msg.sender, from, tokenId, _data);
			return (retval == _ERC721_RECEIVED);
	}

	/**
	* @dev Private function to clear current approval of a given token ID
	* Reverts if the given address is not indeed the owner of the token
		* @param owner owner of the token
	* @param tokenId uint256 ID of the token to be transferred
	*/
	function _clearApproval(address owner, uint256 tokenId) private {
		require(ownerOf(tokenId) == owner);
		if (_tokenApprovals[tokenId] != address(0)) {
			_tokenApprovals[tokenId] = address(0);
		}
	}
}

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter = 1;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

contract illomxMARKET is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

  address owner;
  uint256 listingPrice = 0.0001 ether;

  constructor() {
    owner = (msg.sender);
  }

  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address seller;
    address owner;
    uint256 price;
    bool sold;
  }

  mapping(uint256 => MarketItem) private idToMarketItem;

  event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
  );

  /* Returns the listing price of the contract */
  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  /* Places an item for sale on the marketplace */
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable nonReentrant {
    require(price > 0, "Price must be at least 1 wei");
    require(msg.value == listingPrice, "Price must be equal to listing price");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();

    idToMarketItem[itemId] =  MarketItem(
      itemId,
      nftContract,
      tokenId,
      (msg.sender),
      (address(0)),
      price,
      false
    );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit MarketItemCreated(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      false
    );
  }

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
  function createMarketSale(
    address nftContract,
    uint256 itemId
    ) public payable nonReentrant {
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");

    idToMarketItem[itemId].seller.transfer(msg.value);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    idToMarketItem[itemId].owner = (msg.sender);
    idToMarketItem[itemId].sold = true;
    _itemsSold.increment();
    (owner).transfer(listingPrice);
  }

  /* Returns all unsold market items */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items that a user has purchased */
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint ii = 0; i < totalItemCount; ii++) {
      if (idToMarketItem[ii + 1].owner == msg.sender) {
        uint currentId = ii + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items a user has created */
  function fetchItemsCreated() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint ii = 0; ii < totalItemCount; ii++) {
      if (idToMarketItem[ii + 1].seller == msg.sender) {
        uint currentId = ii + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
}