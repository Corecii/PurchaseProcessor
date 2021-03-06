local PlayerData = require("PlayerData")
local Products = require("Products")

local Bridge = {}

function Bridge.GetPurchaseState(playerId, purchaseId) --> PurchaseState: string | nil
	local data = PlayerData:GetPlayerDataByUserId(playerId)
	return data.PurchaseStates[purchaseId]
end

function Bridge.SetPurchaseState(playerId, purchaseId, state) --> void
	local data = PlayerData:GetPlayerDataByUserId(playerId)
	data.PurchaseStates[purchaseId] = state
end

function Bridge.GetPurchaseTime(playerId, purchaseId) --> PurchaseTime: number | nil
	local data = PlayerData:GetPlayerDataByUserId(playerId)
	return data.PurchaseTimes[purchaseId]
end

function Bridge.SetPurchaseTime(playerId, purchaseId, time) --> void
	local data = PlayerData:GetPlayerDataByUserId(playerId)
	data.PurchaseTimes[purchaseId] = time
end

function Bridge.GetPurchaseTimesDictionary(playerId) --> PurchaseTimes: {[string] = number}
	local data = PlayerData:GetPlayerDataByUserId(playerId)
	return data.PurchaseTimes
end

function Bridge.WaitForDataReady(playerId) --> Continue: boolean
	-- 1. Make sure player is in the game (return false otherwise)
	local player = game.Players:GetPlayerByUserId(purchaseInfo.PlayerId)
	if not player.Parent then
		return false
	end
	-- 2. Wait for the data to load or the player to leave
	local data = PlayerData:WaitForDataReady(playerId)
	if not data then
		return false
	end
	-- 3. Make sure player is in the game (return false otherwise)
	if not player.Parent then
		return false
	end
	-- 4. return true
	return true
end

function Bridge.CanProcessProduct(purchaseInfo) --> CanProcess: boolean
	-- 1. Make sure purchaseInfo.PlayerId is in the game (return false otherwise)
	local player = game.Players:GetPlayerByUserId(purchaseInfo.PlayerId)
	if not player then
		return false
	end
	-- 2. Make sure we have the necessary code to process purchaseInfo.ProductId (return false otherwise)
	local data = PlayerData:GetPlayerDataByUserId(playerId)
	if not data then
		return false
	end
	-- 3. return true
	return true
end

function Bridge.AwardProduct(purchaseInfo) --> Continue: boolean
	local player = game.Players:GetPlayerByUserId(purchaseInfo.PlayerId)
	-- 1. Try to award the product
	Products:AwardProduct(player, purchaseInfo.ProductId)
	-- 2. Make sure purchaseInfo.PlayerId is in the game (return false otherwise)
	if not player.Parent then
		return false
	end
	-- 3. return true
	return true
end

-- A "SessionOnlyProduct" is a product whose effects are not saved with the player at all.
-- A "SessionOnlyProduct" should not touch save data at all.
-- Leaving the server after buying a "SessionOnlyProduct" means you lose that product.
-- This bypasses the saving logic of PurchaseProcessor for extremely simple products.

function Bridge.IsSessionOnlyProduct(productId) --> IsSessionOnlyProduct: boolean
	return false
end

function Bridge.AwardSessionOnlyProduct(purchaseInfo) --> void
	error("Not implemented")
end

return Bridge