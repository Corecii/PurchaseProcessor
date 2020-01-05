
# PurchaseProcessor

*PurchaseProcessor* is a module for Roblox that tracks purchase state to safely award and save purchases.

Most example ProcessReceipt code does not handle edge-cases such that leaving too early, data save failing, or buying another product can lead to lost money or double of a product. *PurchaseProcessor* tracks product purchase state to prevent these things.

## Scenarios

*PurchaseProcessor* handles the following scenarios:

| Scenario | Action |
| :------- | :----- |
| ProcessReceipt called on `purchaseId` that's already being processed | Only process the first time (prevent double awarding) |
| Player leaves during processing | Retry on next join (or refund after 3 days of not playing) |
| Data Stores failing or server crash before saving | Retry on next join (or refund after 3 days of not playing) |
| Data saves very late after awarding product | Return PurchaseGranted for the existing award (prevent double awarding) |
| Awarding product fails | Retry later (or refund after 3 days) (prevent accidental "scams" due to errors) |

## How-to

To use *PurchaseProcessor*, you implement a *bridge*. This bridge lets *PurchaseProcessor* save relevant data and trigger your award-product code.

Here is a [Template Bridge](./Example/TemplateBridge.lua).  
Here is an [Example Bridge](./Example/ExamplePurchaseProcessorBridge.lua).  
Here is an [Example startup script](./Example/ExampleStartup.lua).