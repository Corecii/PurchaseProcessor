
local PurchaseProcessor = require("PurchaseProcessor")
local PurchaseProcessorBridge = require("PurchaseProcessorBridge")

---

local processor = PurchaseProcessor.new(PurchaseProcessorBridge)

local module = {}

function module:Start()
	game.Players.PlayerAdded:Connect(processor.onPlayerAdded)
	game.MarketplaceService.ProcessReceipt = processor.onProcessReceipt
end

return module