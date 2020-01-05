
local PurchaseProcessor = require("PurchaseProcessor")
local PurchaseProcessorBridge = require("PurchaseProcessorBridge")

---

local processor = PurchaseProcessor.new(PurchaseProcessorBridge)

local module = {}

function module:Start()
	game.Players.PlayerAdded:Connect(function(player)
		processor:ProcessPlayerAdded(player)
	end)
	game.MarketplaceService.ProcessReceipt = function(purchaseInfo)
		processor:ProcessPurchase(purchaseInfo)
	end
end

return module