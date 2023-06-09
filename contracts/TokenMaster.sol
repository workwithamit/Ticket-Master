// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenMaster is ERC721 {
    address public owner;
    uint256 public totalOccasions;
    uint256 public totalSupply; //<-- number of minted tickets

    struct Occasion {
        uint256 id;
        string name;
        uint256 cost;
        uint256 tickets;
        uint256 maxTickets;
        string date;
        string time;
        string location;
        address priceFeed; // <-- Chainlink Price Feed address
    }

    mapping(uint256 => Occasion) occasions;
    mapping(uint256 => mapping(uint256 => address)) public seatTaken;
    mapping(uint256 => mapping(address => bool)) public hasBought;
    mapping(uint256 => uint256[]) seatsTaken;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        owner = msg.sender;
    }

    function list(
        string memory _name,
        uint256 _cost,
        uint256 _maxTickets,
        string memory _date,
        string memory _time,
        string memory _location,
        address _priceFeed
    ) public onlyOwner {
        totalOccasions++;
        occasions[totalOccasions] = Occasion(
            totalOccasions,
            _name,
            _cost,
            _maxTickets,
            _maxTickets,
            _date,
            _time,
            _location,
            _priceFeed
        );
    }

    function mint(uint256 _id, uint256 _seat) public payable {
        //checks for id

        require(_id != 0);
        require(_id <= totalOccasions);

        //check for ETH amount
        int256 currentPrice = getLatestPrice(occasions[_id].priceFeed);
        require(currentPrice > 0); // Price must be positive

        uint256 calculatedCost = uint256(currentPrice) * occasions[_id].cost;
        require(msg.value >= calculatedCost);

        //check for seats
        require(seatTaken[_id][_seat] == address(0));
        require(_seat <= occasions[_id].maxTickets);

        //update the ticket count
        occasions[_id].tickets--;

        //update the buying status
        hasBought[_id][msg.sender] = true;
        //assign seat
        seatTaken[_id][_seat] = msg.sender;

        //update the seats currently taken
        seatsTaken[_id].push(_seat);

        totalSupply++;

        _safeMint(msg.sender, totalSupply);
    }

    function getOccasion(uint256 _id) public view returns (Occasion memory) {
        return occasions[_id];
    }

    function getSeatsTaken(uint256 _id) public view returns (uint256[] memory) {
        return seatsTaken[_id];
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

    function getLatestPrice(
        address priceFeedAddress
    ) internal view returns (int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
