// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract AssetManagement {
    
    struct Order {
        address owner;
        uint[2][] req_assets;    
        uint n_assets;
        uint date_take;
        uint date_return;
        uint location;
        bool activated;
        string customer_info;
    }
    
    struct Asset {
        uint asset_id;
        uint type_id;
        uint order_id;
    }
    
    uint orderNr;
    
    mapping(uint => mapping( uint => uint)) totalAssets;
    mapping(uint => mapping( uint => mapping( uint => uint) ) ) reservations; // mapping[ date -> locations -> asset_type -> balance]
    
    mapping(uint => uint ) tmpAssets;
    
    mapping( uint => Order) orders;
    mapping( uint => Asset) assets;
    
    function getOrderNr() private returns (uint) {
        orderNr +=1;
        return orderNr;
    }
    
    function setTotalAssets(uint location,uint type_id,uint n) public {
        totalAssets[location][type_id] = n;
    }
    
    function checkAvailable(uint date,uint location, uint type_id,uint n) view public returns (bool) {
        return reservations[date][location][type_id]+n <= totalAssets[location][type_id];
    }
    
    function assignAsset(uint asset_id,uint order_id) public {
        require(assets[asset_id].order_id == 0);
        assets[asset_id].order_id = order_id;
    }
    
    function releaseAsset(uint asset_id,uint order_id) public {
        require(assets[asset_id].order_id == order_id);
        delete assets[asset_id];
    }
    
    function subtractReservation(uint date,uint location,uint asset_id,uint n) public {
        reservations[date][location][asset_id] -= n;
    }
    
    function addReservation(uint date,uint location,uint asset_id,uint n) public {
        reservations[date][location][asset_id] += n;
    }
    
    function addOrder(uint location,uint date_take,uint date_return, uint[2][] memory req_assets) public {
        uint n_assets = 0;
        for (uint i=0; i<req_assets.length; i++) {
            require(checkAvailable(date_take,location,req_assets[i][0], req_assets[i][1]));
            addReservation(date_take, location, req_assets[i][0], req_assets[i][1]);
            n_assets += req_assets[i][1];
        }
        uint order_nr = getOrderNr();
        orders[order_nr] = Order(msg.sender, req_assets, n_assets, date_take, date_return, location,false, "test");
    }
    
    function removeOrder(uint order_nr) public {
        Order memory order = orders[order_nr];
        for (uint i=0; i<order.req_assets.length; i++) {
            subtractReservation(order.date_take,order.location, order.req_assets[i][0], order.req_assets[i][1]);
        }
        delete orders[order_nr];
    }

    function assignAssetsToOrder(uint order_nr, uint[] memory asset_nrs) public {
        Order storage order = orders[order_nr];
        require(asset_nrs.length == order.n_assets);
        for (uint i=0; i<asset_nrs.length; i++) {
            assignAsset(order_nr,asset_nrs[i]);
            tmpAssets[assets[asset_nrs[i]].type_id] += 1;
        }
        for (uint i=0; i<order.req_assets.length; i++) {
            require(tmpAssets[order.req_assets[i][0]] == order.req_assets[i][1]);
            delete tmpAssets[order.req_assets[i][0]];
        }
    }
    
    function releaseAssetsFromOrder(uint order_nr,uint[] memory asset_nrs) public {
        Order memory order = orders[order_nr];
        require(asset_nrs.length == order.n_assets);
        for (uint i=0; i<order.req_assets.length; i++) {
            releaseAsset(order_nr,asset_nrs[i]);
        }
    }
    
    function createOrder(uint location,uint date_take,uint date_leave,uint[2][] memory req_assets) public {
        addOrder(location,date_take,date_leave, req_assets);
    }
    
    function cancelOrder(uint order_nr) public {
        require(!orders[order_nr].activated);
        removeOrder(order_nr);
    }
    
    function activateOrder(uint order_nr,uint[] memory asset_nrs) public {
        assignAssetsToOrder(order_nr, asset_nrs);
        orders[order_nr].activated = true;
    }
    
    
}
