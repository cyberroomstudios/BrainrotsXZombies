local Response = {}

-- Init Bridge Net
local BridgeNet2 = require(script.Parent.BridgeNet2)
local bridge = BridgeNet2.ReferenceBridge("StockService")
local actionIdentifier = BridgeNet2.ReferenceIdentifier("action")
local statusIdentifier = BridgeNet2.ReferenceIdentifier("status")
local messageIdentifier = BridgeNet2.ReferenceIdentifier("message")
-- End Bridge Net

-- === GLOBAL STATIC VARIABLES
Response.MESSAGES = {
	ITEM_PURCHASED = "ITEM_PURCHASED",
	ITEM_RESTOCKED = "ITEM_RESTOCKED",
	INVALID_CATEGORY = "INVALID_CATEGORY",
	INVALID_ITEM = "INVALID_ITEM",
	INVALID_PAYLOAD = "INVALID_PAYLOAD",
	INVALID_TYPE = "INVALID_TYPE",
	INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS",
	OUT_OF_STOCK = "OUT_OF_STOCK",
	PLAYER_RESTOCKED = "PLAYER_RESTOCKED",
	PRICES_UPDATED = "PRICES_UPDATED",
	PRODUCT_NOT_CONFIGURED = "PRODUCT_NOT_CONFIGURED",
	PROMPT_FAILED = "PROMPT_FAILED",
	PURCHASE_PENDING = "PURCHASE_PENDING",
	STOCK_UPDATED = "STOCK_UPDATED",
	UNAVAILABLE_SLOT = "UNAVAILABLE_SLOT",
	UNKNOWN_ACTION = "UNKNOWN_ACTION",
}

-- === GLOBAL STATIC FUNCTIONS
function Response.makeResponse(status: string, message: string, extra: table?): table
	local result = {
		[statusIdentifier] = status,
		[messageIdentifier] = message,
	}
	if extra then
		for key, value in pairs(extra) do
			result[key] = value
		end
	end
	return result
end

function Response.makeError(message: string, extra: table?): table
	return Response.makeResponse("error", message, extra)
end

function Response.makeSuccess(message: string, extra: table?): table
	return Response.makeResponse("success", message, extra)
end

function Response.isSuccessResponse(response: any): boolean
	return typeof(response) == "table" and response[statusIdentifier] == "success"
end

return Response
