pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
contract FractionalNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    struct FractionDetails {
        uint noOfFractions;
        address[] owners;
        uint[] prices;
    }
    mapping(uint => string ) tokenURIs;
    mapping(uint => bool) public isFractioned;
    mapping(uint => uint) public tokenPrices;
    mapping(uint => FractionDetails) public fractionDetails;

    constructor() ERC721("FractionalNFT", "F-NFT") {
        _tokenId.increment();
    }

    function mint(string memory uri,uint price) external {
        tokenURIs[_tokenId.current()] = uri;
        tokenPrices[_tokenId.current()] = price;
        _mint(msg.sender);
    }

    function _mint(address _to) private {
        uint256 tokenId = _tokenId.current();
        _safeMint(_to, tokenId);
    }

    function tokenURI(uint id) public view virtual override returns (string memory) {
        return tokenURIs[id];
    }

    function fractionalizedNFT(uint _id,uint noOfFractions, uint price) external {
        require(ownerOf(_id) == msg.sender , "You are not the owner.");
        require(isFractioned[_id] == false , "NFT is already fractionalized.");
        isFractioned[_id] = true;
        address[] memory owners = new address[](noOfFractions);
        uint[] memory prices = new uint256[](noOfFractions);

        for(uint i = 0 ; i < noOfFractions ; i++){
            owners[i]=msg.sender;
            prices[i]=price;  
        }

        tokenPrices[_id] = price * noOfFractions;
        fractionDetails[_id] = FractionDetails(noOfFractions,owners,prices);
    }

    function combineNFT(uint _id, uint price) external {
        require(ownerOf(_id) == msg.sender , "You are not the owner.");
        require(isFractioned[_id] == true , "NFT is already not fractionalized.");
        require(checkBeforeCombine(_id,msg.sender) == true,"You don't own the entire NFT.");
        
        address[] memory owners = new address[](0);
        uint[] memory prices = new uint256[](0);

        isFractioned[_id] = false;
        tokenPrices[_id] = price;
        fractionDetails[_id] = FractionDetails(0,owners,prices);
    }

    function checkBeforeCombine(uint _id , address owner) internal view returns (bool){
        address[] memory owners = fractionDetails[_id].owners;
        for(uint i = 0 ; i < owners.length ; i++){
            if(owners[i]!=owner){
                return false;
            }
        }
        return true;
    }

    function changeFractionPrice(uint tokenId, uint fraction , uint price) external {
        require (fractionDetails[tokenId].owners[fraction-1] == msg.sender, "You are not the owner of this fraction of the NFT.");
        fractionDetails[tokenId].prices[fraction-1] = price;
    }

    function transferFraction(uint tokenId, uint fraction , address to) external {
        require (fractionDetails[tokenId].owners[fraction-1] == msg.sender);
        fractionDetails[tokenId].owners[fraction-1] = to;
    }

    function tokenDetails(uint _id) public view returns ( uint , address[] memory , uint[] memory){

        if(isFractioned[_id]==true){
            return (fractionDetails[_id].noOfFractions,fractionDetails[_id].owners,fractionDetails[_id].prices);
        }else{
            address[] memory owner = new address[](1);
            uint[] memory price = new uint[](1);
            owner[0]=ownerOf(_id);
            price[0]=tokenPrices[_id];
            return (0,owner,price);
        }

    }

}