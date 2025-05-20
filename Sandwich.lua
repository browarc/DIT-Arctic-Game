local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Order = require(ReplicatedStorage.Orders)
 
-- Type Definitions
type TrayModel = typeof(script.Tray)
type SandwichInfo = {
	Tray: TrayModel,
	TotalAdded: Vector3,
	CFrameValue: CFrameValue,
	Sandwich: Order.Sandwich
}
 
export type SandwichImpl = {
	TrayCFrame: CFrame,
	Create: () -> number,
	Modify: (Attr: string, Value: any) -> (),
	GetIngredient: (IngredientName: string, CFrame: CFrame) -> PVInstance,
	ThrowAway: (UID: number) -> (),
	CompleteSandwich: (UID: number) -> (),
}
 
-- Module Table
local Sandwich = {} :: SandwichImpl
 
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
 
-- Modules
local Sound 
local Mouse = require(ReplicatedStorage.Tool.Mouse)
local Spring = require(ReplicatedStorage.Tool.Spring)
local IngredientCollection = require(ReplicatedStorage.Ingredients)
 
-- Bindable Events
local CantSendFood = ReplicatedStorage.Bindable.CantSendFood
 
-- Constants
local FoodParts = {}
for _, V in IngredientCollection do FoodParts[V.Name] = V.Model end
 
local LocalPlayer = Players.LocalPlayer
local TrayPositions = workspace.TrayPositions
local Tray = script.Tray
local TrayFolder = workspace.Trays
local SlideTime = 0.2
 
-- Private Variables
local SandwichesInProgress: { [number]: SandwichInfo } = {}
local TrayPositionCFrames: { CFrame } = {}
local UID = 0
 
for _, V in TrayPositions:GetChildren() do
	TrayPositionCFrames[tonumber(V.Name) :: number] = V:GetPivot()
end
 
local function MoveTray(TrayInstance: Instance, TargetCFrame: CFrame, Duration: number)
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = TrayInstance:GetPivot()
	CFrameValue.Parent = TrayInstance
 
	CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		TrayInstance:PivotTo(CFrameValue.Value)
	end)
	local Tween = TweenService:Create(CFrameValue, TweenInfo(Duration), {Value = TargetCFrame})
	Tween:Play()
	return CFrameValue
end
 
function Sandwich.Create()
	UID += 1
	local TrayClone = Tray:Clone()
	local CFrameValue = MoveTray(TrayClone, TrayPositions[2], SlideTime)
	TrayClone.Parent = TrayFolder
 
	local NewSandwich = {}
	for _, V in IngredientCollection do 
		NewSandwich[V.Name] = false
	end
	SandwichesInProgress[UID] ={
		Sandwich = NewSandwich,
		CFrameValue = CFrameValue,
		Tray = TrayClone,
		TotalAdded  = Vector3.zero
	}
	return UID
end
 
function Sandwich.Modify(Attribute, Value)
	--try write urself
end
