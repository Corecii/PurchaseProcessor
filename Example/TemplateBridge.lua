
local PurchaseProcessorBridge = {}

function PurchaseProcessorBridge:GetPurchaseState(playerId, purchaseId) --> PurchaseState: string | nil

end

function PurchaseProcessorBridge:SetPurchaseState(playerId, purchaseId, state) --> void

end

function PurchaseProcessorBridge:GetPurchaseTime(playerId, purchaseId) --> PurchaseTime: number | nil

end

function PurchaseProcessorBridge:SetPurchaseTime(playerId, purchaseId, time) --> void

end

function PurchaseProcessorBridge:GetPurchaseTimesDictionary(playerId) --> PurchaseTimes: {[string] = number}

end

function PurchaseProcessorBridge:WaitForDataReady(player) --> Continue: boolean
	-- 1. Make sure player is in the game (return false otherwise)
	-- 2. Wait for the data to load or the player to leave
	-- 3. Make sure player is in the game (return false otherwise)
	-- 4. return true
end

function PurchaseProcessorBridge:CanProcessProduct(purchaseInfo) --> CanProcess: boolean
	-- 1. Make sure purchaseInfo.PlayerId is in the game (return false otherwise)
	-- 2. Make sure we have the necessary code to process purchaseInfo.ProductId (return false otherwise)
	-- 3. return true
end

function PurchaseProcessorBridge:AwardProduct(purchaseInfo) --> Continue: boolean
	-- 1. Try to award the product
	-- 2. Make sure purchaseInfo.PlayerId is in the game (return false otherwise)
	-- 3. return true
end

-- A "NotSavedProduct" is a product whose effects are not saved with the player at all.
-- A "NotSavedProduct" should not touch save data at all.
-- Leaving the server after buying a "NotSavedProduct" means you lose that product.
-- This bypasses the saving logic of PurchaseProcessor for extremely simple products.

function PurchaseProcessorBridge:IsNotSavedProduct(productId) --> IsNotSavedProduct: boolean

end

function PurchaseProcessorBridge:AwardNotSavedProduct(purchaseInfo) --> void

end

return PurchaseProcessorBridge