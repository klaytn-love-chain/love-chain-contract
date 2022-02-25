pragma experimental ABIEncoderV2;
pragma solidity >=0.4.24 <=0.5.6;

contract LoveChain {
    string public name = "LoveChain";
    string public symbol = "LC";

    address private deployer; // 배포자 주소
    address private NSeoulTowerMarketAddress; // 남산마켓 주소

    constructor() public {
        deployer = msg.sender;
    }

    mapping (uint256 => address) public tokenOwner;
    mapping (uint256 => uint256) public lastTransactionPrice;

    mapping (uint256 => string) private _tokenURIs;
    mapping (address => uint256[]) private _ownerTokens;
    mapping (uint256 => string[]) private _tokenCoupleName;

    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;
    uint256 private constant MINT_PRICE = 2; // 민팅 가격;

    modifier onlyDeployer () {
        require(msg.sender == deployer, "you are not deployer");
        _;
    }

    function setNSeoulMarketAddress(address marketAddress) public onlyDeployer { // 남산마켓 주소를 저장하기 위한 함수
        NSeoulTowerMarketAddress = marketAddress;
    }

    function mintWithTokenURI(address to, uint256 tokenId, string memory URI) public onlyDeployer returns (bool) {
        require(tokenOwner[tokenId] == address(0), "already minted tokenId");
        tokenOwner[tokenId] = address(to);
        if(to == NSeoulTowerMarketAddress) { // 마켓으로 민팅한다면 가격 정보를 전달
            NSeoulTowerMarket(to).setMintedToken(tokenId, MINT_PRICE);
        }

        _tokenURIs[tokenId] = URI;
        _ownerTokens[address(to)].push(tokenId);

        return true;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        // _data에는 가격 정보를 담아준다.
        // ex) 0x0000000000000000000000000000000000000000000000000000000000000001 = 1
        require(from == msg.sender, "from != msg.sender");
        require(from == tokenOwner[tokenId], "you are not the owner of the token");
        
        _removeTokenFromList(from, tokenId);
        _ownerTokens[to].push(tokenId);
        _clearCoupleName(tokenId);

        tokenOwner[tokenId] = to;

        if (from == NSeoulTowerMarketAddress) { // 마켓에서 전송되는 경우(= 거래가 발생) 최근 거래 가격을 업데이트
            _updateLastTransactionPrice(tokenId, _data);
        }

        require(
            _checkOnKIP17Received(from, to, tokenId, _data), "KIP17: transfer to non KIPReceiver implementer"
        );
    }

    function _checkOnKIP17Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
        bool success;
        bytes memory returndata;

        if (!isContract(to)) {
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(
                _KIP17_RECEIVED,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        if (
            returndata.length != 0 &&
            abi.decode(returndata, (bytes4)) == _KIP17_RECEIVED
        ) {
            return true;
        }
        return false;
    }
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account)}
        return size > 0;
    }

    function _removeTokenFromList(address from, uint256 tokenId) private {
        for (uint256 i = 0; i < _ownerTokens[from].length; i++) {
            if (tokenId == _ownerTokens[from][i]) {
                _ownerTokens[from][i] = _ownerTokens[from][_ownerTokens[from].length - 1];
                break;
            }
        }
        _ownerTokens[from].length--;
    }

    function writeCoupleName(uint256 tokenId, string memory name1, string memory name2) public { // 커플 이름 등록
        require(tokenOwner[tokenId] == msg.sender, "tokenOwner != sender");

        _clearCoupleName(tokenId);
        _tokenCoupleName[tokenId].push(name1);
        _tokenCoupleName[tokenId].push(name2);
    }

    function _clearCoupleName(uint256 tokenId) private { // 커플 이름 삭제
        delete _tokenCoupleName[tokenId];
    }

    function ownedTokens(address owner) public view returns (uint256[] memory) {
        return _ownerTokens[owner];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function coupleNamesOf(uint256 tokenId) public view returns (string[] memory) { // 커플 이름 조회
        return _tokenCoupleName[tokenId];
    }

    function _bytestoUint256(bytes memory _bytes) internal pure returns (uint256 value) { // 타입캐스팅
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function _updateLastTransactionPrice(uint256 tokenId, bytes memory priceData) internal { // 최신 거래 가격 업데이트
        uint256 p = _bytestoUint256(priceData);

        if(p != 0) lastTransactionPrice[tokenId] = p;
    }
}

contract NSeoulTowerMarket {

    address private _LoveChainAddress;
    address private _deployer;

    uint256 private constant NFT_NUMBERS = 500;
    
    constructor(address LoveChainAddress) public {
        _LoveChainAddress = LoveChainAddress;
        _deployer = msg.sender;
    }

    mapping (uint256 => address) public seller;
    mapping (uint256 => uint256) public price;

    function buyLoveChain(uint256 tokenId) public payable returns (bool) {
        address payable receiver = address(uint256(seller[tokenId]));
        uint256 _price = price[tokenId];

        receiver.transfer(_price * (10 ** 18));
        LoveChain(_LoveChainAddress).safeTransferFrom(address(this), msg.sender, tokenId, _uint256toBytes(_price)); // data로 거래 가격을 전송
        _clearSeller(tokenId);
        _clearPrice(tokenId);

        return true;
    }

    function cancleSelling(uint256 tokenId) public returns (bool) {
        address owner = address(uint256(seller[tokenId]));
        require(owner == msg.sender, "you are not token's onwer");

        LoveChain(_LoveChainAddress).safeTransferFrom(address(this), msg.sender, tokenId, _uint256toBytes(0)); // 취소하는 경우 0원으로 전송
        _clearSeller(tokenId);
        _clearPrice(tokenId);

        return true;
    }

    function _clearSeller(uint256 tokenId) private { // 거래 완료 시 seller 정보 삭제
        delete seller[tokenId];
    }

    function _clearPrice(uint256 tokenId) private { // 거래 완료 시 price 정보 삭제
        delete price[tokenId];
    }

    function _bytestoUint256(bytes memory _bytes) internal pure returns (uint256 value) { // 타입캐스팅
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function _uint256toBytes(uint256 _uint256) internal pure returns (bytes memory value) { // 타입캐스팅
        value = new bytes(32);
        assembly { 
            mstore(add(value, 32), _uint256) 
        }
    }

    function setMintedToken(uint256 tokenId, uint256 _price) public { // 마켓으로 민팅할 때 price를 설정하기 위한 함수
        require(msg.sender == _LoveChainAddress, "you are not LoveChain");
        seller[tokenId] = _deployer;
        price[tokenId] = _price;
    }

    function onKIP17Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        require(tokenId <= NFT_NUMBERS, "This token is not placed in NSeoulTower"); // 마켓이 받은 NFT가 남산타워의 것이 맞는지?
        seller[tokenId] = from; // 판매자 주소 등록
        price[tokenId] = _bytestoUint256(data); // data로 받아온 price 저장

        return bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"));
    }
}