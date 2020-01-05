
local PurchaseProcessor = require("PurchaseProcessor")
local PurchaseProcessorBridge = require("PurchaseProcessorBridge")

---

local module = {}

function module:Start()
	PurchaseProcessor.SetBridge(PurchaseProcessorBridge)
	game.Players.PlayerAdded:Connect(PurchaseProcessor.PlayerAdded)
	game.MarketplaceService.ProcessReceipt = PurchaseProcessor.ProcessReceipt
end

return module