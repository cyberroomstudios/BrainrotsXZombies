local ClientSignal = {}
ClientSignal.__index = ClientSignal

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> { Disconnect: () -> () },
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> (),
	Fire: (self: Signal<T...>, T...) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

function ClientSignal.new<T...>(): Signal<T...>
	local self = setmetatable({
		_connections = {} :: { (T...) -> () },
	}, ClientSignal)
	return self :: Signal<T...>
end

function ClientSignal:Connect<T...>(callback: (T...) -> ())
	table.insert(self._connections, callback)
	return {
		Disconnect = function()
			for i, conn in ipairs(self._connections) do
				if conn == callback then
					table.remove(self._connections, i)
					break
				end
			end
		end,
	}
end

function ClientSignal:Once<T...>(callback: (T...) -> ())
	local wrapper
	wrapper = function(...)
		callback(...)
		for i, conn in ipairs(self._connections) do
			if conn == wrapper then
				table.remove(self._connections, i)
				break
			end
		end
	end
	self:Connect(wrapper)
end

function ClientSignal:Fire(...)
	for _, callback in ipairs(self._connections) do
		task.spawn(callback, ...)
	end
end

function ClientSignal:Destroy()
	table.clear(self._connections)
end

return ClientSignal
