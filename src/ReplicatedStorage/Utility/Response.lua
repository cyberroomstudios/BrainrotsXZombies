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
	EGG_ADDED = "EGG_ADDED",
	EGG_COLLECTED = "EGG_COLLECTED",
	EGG_HATCHED = "EGG_HATCHED",
	ITEM_PURCHASED = "ITEM_PURCHASED",
	ITEM_RESTOCKED = "ITEM_RESTOCKED",
	INVALID_ACTION = "INVALID_ACTION",
	INVALID_CATEGORY = "INVALID_CATEGORY",
	INVALID_ITEM = "INVALID_ITEM",
	INVALID_PAYLOAD = "INVALID_PAYLOAD",
	INVALID_RANKING_TYPE = "INVALID_RANKING_TYPE",
	INVALID_TYPE = "INVALID_TYPE",
	INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS",
	ORDERED_DATA_STORE_ERROR = "ORDERED_DATA_STORE_ERROR",
	OUT_OF_STOCK = "OUT_OF_STOCK",
	PLAYER_DATA_LOADED = "PLAYER_DATA_LOADED",
	PLAYER_DATA_RETRIEVED = "PLAYER_DATA_RETRIEVED",
	PLAYER_RANKING_UPDATED = "PLAYER_RANKING_UPDATED",
	PLAYER_RESTOCKED = "PLAYER_RESTOCKED",
	PRICES_UPDATED = "PRICES_UPDATED",
	PRODUCT_NOT_CONFIGURED = "PRODUCT_NOT_CONFIGURED",
	PROMPT_FAILED = "PROMPT_FAILED",
	PURCHASE_PENDING = "PURCHASE_PENDING",
	RANKING_DATA_RETRIEVED = "RANKING_DATA_RETRIEVED",
	STOCK_UPDATED = "STOCK_UPDATED",
	UNAVAILABLE_SLOT = "UNAVAILABLE_SLOT",
	UNAVAILABLE_WEAPON = "UNAVAILABLE_WEAPON",
	UNKNOWN = "UNKNOWN",
}

Response.STATUS = {
	SUCCESS = "success",
	ERROR = "error",
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
	return Response.makeResponse(Response.STATUS.ERROR, message, extra)
end

function Response.makeSuccess(message: string, extra: table?): table
	return Response.makeResponse(Response.STATUS.SUCCESS, message, extra)
end

function Response.isSuccessResponse(response: any): boolean
	return typeof(response) == "table" and response[statusIdentifier] == Response.STATUS.SUCCESS
end

return Response
