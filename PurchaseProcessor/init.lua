local PURCHASE_CUTOFF = 60*60*24*4 -- remove purchases after 4 days

local PurchaseProcessor = {}
PurchaseProcessor.__index = PurchaseProcessor

function PurchaseProcessor.new(bridge)
	local self = setmetatable({}, PurchaseProcessor)
	self.bridge = bridge
	self.onPlayerAdded = function(player)
		return self:ProcessPlayerAdded(player)
	end
	self.onProcessReceipt = function(purchaseInfo)
		return self:ProcessPurchase(purchaseInfo)
	end
	return self
end

function PurchaseProcessor:ProcessPurchase(purchaseInfo)
	-- purchaseInfo fields:
	-- PurchaseId
	-- PlayerId
	-- ProductId
	-- CurrencySpent
	-- CurrencyType
	-- PlaceIdWherePurchased

	if self.bridge.IsNotSavedProduct(purchaseInfo.ProductId) then
		local success, error = pcall(function()
			self.bridge.AwardNotSavedProduct(purchaseInfo)
		end)
		if not success then
			error(("[PurchaseProcessor] Failed to award not-saved product %d for %d (%s) because:"):format(purchaseInfo.ProductId, purchaseInfo.PlayerId, tostring(purchaseInfo.PurchaseId)))
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local canContinue = self.bridge.WaitForDataReady(purchaseInfo.PlayerId)
	if not canContinue then
		warn(("[PurchaseProcessor] ProcessPurchase cancelled because WaitForDataReady returned falsey. Player: %d"):format(purchaseInfo.PlayerId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not self.bridge.CanProcessProduct(purchaseInfo) then
		warn(("[PurchaseProcessor] ProcessPurchase cancelled because CanProcessProduct returned falsey. Player: %d; Product: %d; PurchaseId: %s"):format(purchaseInfo.PlayerId, purchaseInfo.ProductId, tostring(purchaseInfo.PurchaseId)))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseState = self.bridge.GetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId)
	if purchaseState == "Working" or purchaseState == "Saving" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	elseif purchaseState == "Saved" then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif purchaseState ~= nil then
		error(("[PurchaseProcessor] Unknown purchase state %s (should be 'Working', 'Saving', 'Saved', or nil)"):format(tostring(purchaseState)))
	end

	self.bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, "Working")
	if not self.bridge.GetPurchaseTime(purchaseInfo.PlayerId, purchaseInfo.PurchaseId) then
		self.bridge.SetPurchaseTime(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, os.time())
	end

	local canContinue = false
	local success, error = pcall(function()
		canContinue = self.bridge.AwardProduct(purchaseInfo)
	end)
	if not success then
		self.bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, nil)
		error(("[PurchaseProcessor] Failed to award product %d for %d (%s) because:"):format(purchaseInfo.ProductId, purchaseInfo.PlayerId, tostring(purchaseInfo.PurchaseId)))
	end
	if not canContinue then
		self.bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, nil)
		warn(("[PurchaseProcessor] ProcessPurchase cancelled because AwardProduct returned falsey. Player: %d; Product: %d; PurchaseId: %s"):format(purchaseInfo.PlayerId, purchaseInfo.ProductId, tostring(purchaseInfo.PurchaseId)))
	end

	self.bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, "Saving")
	local hasSaved = self.bridge.YieldUntilSaved(purchaseInfo.PlayerId)
	if hasSaved then
		self.bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, "Saved")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function PurchaseProcessor:ProcessPlayerAdded(player)
	local canContinue = self.bridge.WaitForDataReady(player.UserId)
	if not canContinue then
		warn(("[PurchaseProcessor] ProcessPlayerAdded cancelled because WaitForDataReady returned falsey. Player: %d"):format(player.UserId))
		return
	end

	local playerId = player.UserId

	local purchaseTimes = self.bridge.GetPurchaseTimesDictionary(playerId)

	local cutoff = os.time() - PURCHASE_CUTOFF
	for purchaseId, osTime in pairs(purchaseTimes) do
		if osTime < cutoff then
			self.bridge.SetPurchaseTime(playerId, purchaseId, nil)
			self.bridge.SetPurchaseState(playerId, purchaseId, nil)
		else
			local state = self.bridge.GetPurchaseState(playerId, purchaseId)
			if state == "Saving" then
				self.bridge.SetPurchaseState(playerId, purchaseId, "Saved")
			elseif state == "Working" then
				self.bridge.SetPurchaseState(playerId, purchaseId, nil)
			end
		end
	end
end

return PurchaseProcessor