local PURCHASE_CUTOFF = 60*60*24*4 -- remove purchases after 4 days

local bridge
local bridgeDebugTraceback
local bridgeDebugTick

local PurchaseProcessor = {}

function PurchaseProcessor.SetBridge(newBridge)
	local traceback = debug.traceback()
	if bridge then
		warn(("PurchaseProcessor Bridge was already set %.3f seconds ago from %s"):format(tick() - bridgeDebugTick, bridgeDebugTraceback))
		warn(("Called from %s"):format(traceback))
	end
	bridge = newBridge
	bridgeDebugTraceback = traceback
	bridgeDebugTick = tick()
end

function PurchaseProcessor.ProcessReceipt(purchaseInfo)
	-- purchaseInfo fields:
	-- PurchaseId
	-- PlayerId
	-- ProductId
	-- CurrencySpent
	-- CurrencyType
	-- PlaceIdWherePurchased

	if not bridge then
		error("[PurchaseProcessor] Bridge not set. Call PurchaseProcessor.SetBridge(bridge) before using PurchaseProcessor")
	end

	if bridge.IsNotSavedProduct(purchaseInfo.ProductId) then
		local success, error = pcall(function()
			bridge.AwardNotSavedProduct(purchaseInfo)
		end)
		if not success then
			error(("[PurchaseProcessor] Failed to award not-saved product %d for %d (%s) because:"):format(purchaseInfo.ProductId, purchaseInfo.PlayerId, tostring(purchaseInfo.PurchaseId)))
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local canContinue = bridge.WaitForDataReady(purchaseInfo.PlayerId)
	if not canContinue then
		warn(("[PurchaseProcessor] ProcessReceipt cancelled because WaitForDataReady returned falsey. Player: %d"):format(purchaseInfo.PlayerId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not bridge.CanProcessProduct(purchaseInfo) then
		warn(("[PurchaseProcessor] ProcessReceipt cancelled because CanProcessProduct returned falsey. Player: %d; Product: %d; PurchaseId: %s"):format(purchaseInfo.PlayerId, purchaseInfo.ProductId, tostring(purchaseInfo.PurchaseId)))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseState = bridge.GetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId)
	if purchaseState == "Working" or purchaseState == "Saving" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	elseif purchaseState == "Saved" then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif purchaseState ~= nil then
		error(("[PurchaseProcessor] Unknown purchase state %s (should be 'Working', 'Saving', 'Saved', or nil)"):format(tostring(purchaseState)))
	end

	bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, "Working")
	if not bridge.GetPurchaseTime(purchaseInfo.PlayerId, purchaseInfo.PurchaseId) then
		bridge.SetPurchaseTime(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, os.time())
	end

	local canContinue = false
	local success, error = pcall(function()
		canContinue = bridge.AwardProduct(purchaseInfo)
	end)
	if not success then
		bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, nil)
		error(("[PurchaseProcessor] Failed to award product %d for %d (%s) because:"):format(purchaseInfo.ProductId, purchaseInfo.PlayerId, tostring(purchaseInfo.PurchaseId)))
	end
	if not canContinue then
		bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, nil)
		warn(("[PurchaseProcessor] ProcessReceipt cancelled because AwardProduct returned falsey. Player: %d; Product: %d; PurchaseId: %s"):format(purchaseInfo.PlayerId, purchaseInfo.ProductId, tostring(purchaseInfo.PurchaseId)))
	end

	bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, "Saving")
	local hasSaved = bridge.YieldUntilSaved(purchaseInfo.PlayerId)
	if hasSaved then
		bridge.SetPurchaseState(purchaseInfo.PlayerId, purchaseInfo.PurchaseId, "Saved")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function PurchaseProcessor.PlayerAdded(player)
	if not bridge then
		error("[PurchaseProcessor] Bridge not set. Call PurchaseProcessor.SetBridge(bridge) before using PurchaseProcessor")
	end

	local canContinue = bridge.WaitForDataReady(player.UserId)
	if not canContinue then
		warn(("[PurchaseProcessor] ProcessPlayerAdded cancelled because WaitForDataReady returned falsey. Player: %d"):format(player.UserId))
		return
	end

	local playerId = player.UserId

	local purchaseTimes = bridge.GetPurchaseTimesDictionary(playerId)

	local cutoff = os.time() - PURCHASE_CUTOFF
	for purchaseId, osTime in pairs(purchaseTimes) do
		if osTime < cutoff then
			bridge.SetPurchaseTime(playerId, purchaseId, nil)
			bridge.SetPurchaseState(playerId, purchaseId, nil)
		else
			local state = bridge.GetPurchaseState(playerId, purchaseId)
			if state == "Saving" then
				bridge.SetPurchaseState(playerId, purchaseId, "Saved")
			elseif state == "Working" then
				bridge.SetPurchaseState(playerId, purchaseId, nil)
			end
		end
	end
end

return PurchaseProcessor