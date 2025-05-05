--!strict

--[[
TYPES
Sandwich: A table with ingredient names as keys and true as values
Order: A table representing a single order
OrdersImpl: The main system managing all orders

Main Table - Order
Keeps track of orders
Has event signals (OrderAdded, OrderRemoved)
Implements order related functions

]]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Tool.Signal)

export type Sandwich = {[string] : boolean}

export type Order = {
	Uid: number,
	CreateTime: number,
	ExpireTime: number,
	IsVip: boolean,
	ItemsAsked: {Sandwich},
	ItemsGiven: {Sandwich},
}

export type OrderImpl = {
	NumOrders: number,
	Orders: {Order},
	
	OrderAdded: Signal.Signal,
	OrderRemoved: Signal.Signal,
	ItemAdded: Signal.Signal,
	
	AddOrder: (OrderInfo: {Sandwich}, IsVip: boolean) -> number,
	GetOrder: (Uid: number) -> Order?,
	RemoveOrder: (Uid: number, OrderComplete: boolean) -> (),
	
	AddSandwichToOrder: (Sandwich: Sandwich) -> boolean,
	
	ResetUID: () -> ()
}

--Module Table:
local Order = {
	Orders = {},
	NumOrders = 0,
	
	OrderAdded = Signal.new(),
	OrderRemoved = Signal.new(),
	ItemAdded = Signal.new()
	
} :: OrderImpl

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local S

local OrderTimer = 15

local Uid = 0
local Orders = Order.Orders

function Order.AddOrder(Sandwiches, IsVip)
	Uid += 1
	Order.NumOrders += 1
	
	local CreateTime = os.clock()
	Orders[Uid] = {
		Uid = Uid,
		CreateTime = CreateTime,
		ExpireTime = CreateTime + OrderTimer/(if IsVip then 2 else 1),
		ItemsAsked = Sandwiches,
		IsVip = IsVip,
		ItemsGiven = {}
	}
	Order.OrderAdded:Fire(Orders[Uid])
	return Uid
end

function Order.AddSandwichToOrder(Sandwich)
	local ClosestTime = math.huge
	local BestOrderUid = nil
	local SandwichIndex = nil
	
	-- Find the best order to add the sandwich to (earliest expiry)
	for Uid, Order in Orders do
		if Order.ExpireTime >= ClosestTime then continue end
		
		for i, RequestedSandwich in Order.ItemsAsked do
			local IsMatch = true
			for Ingredient, HasNeededIngredient in RequestedSandwich do
				if Sandwich[Ingredient] ~= HasNeededIngredient then
					IsMatch = false
					break
				end
			end
			
			if IsMatch then
				-- Found a matching sandwich in this order
				ClosestTime = Order.ExpireTime
				BestOrderUid = Uid
				SandwichIndex = i
				break -- Stop checking this order
			end
		end
	end
	-- If no suitable order was found, return false
	if not  BestOrderUid or not SandwichIndex then return false end
	
	local Orderr = Orders[BestOrderUid]
	
	local AddedSandwich = table.remove(Orderr.ItemsAsked, SandwichIndex) :: Sandwich
	table.insert(Orderr.ItemsGiven, AddedSandwich)
	
	Order.ItemAdded:Fire(BestOrderUid, AddedSandwich)
	
	if #Orderr.ItemsAsked == 0 then
		Order.RemoveOrder(BestOrderUid, true)
	else
		print("add sound here ")
	end
	return true
end

function Order.GetOrder(Uid)
	return Orders[Uid]
end

function Order.RemoveOrder(Uid, OrderComplete)
	if Orders[Uid] == nil then return end
	Order.NumOrders -= 1
	Orders[Uid] = nil
	
	print("	Sound.PlayGlobalSound(if order_complete then OrderComplete else OrderFailed")
	Order.OrderRemoved:Fire(Uid, OrderComplete)
end

function Order.ResetUID()
	Uid = 0
end

return Order
