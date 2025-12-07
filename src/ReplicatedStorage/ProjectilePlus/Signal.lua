type Connection = {
	Disconnect: () -> (),
}

local Signal = {}
Signal.__index = Signal

function Signal.new<T>(): Signal<T>
	return setmetatable({
		_listeners = {},
	}, Signal)
end

function Signal:Connect(callback: (T) -> ()): Connection
	table.insert(self._listeners, callback)
	local conn: Connection
	conn = {
		Disconnect = function()
			local index = table.find(self._listeners, callback)
			if index then
				table.remove(self._listeners, index)
			end
		end,
	}
	return conn
end

function Signal:Once(callback: (T) -> ()): Connection
	local conn: Connection? = nil
	local wrapper = function(value: T)
		if conn then
			conn.Disconnect()
		end
		callback(value)
	end
	conn = self:Connect(wrapper)
	return conn
end

function Signal:Fire(value: any)
	local listeners = table.clone(self._listeners)
	for _, callback in ipairs(listeners) do
		task.spawn(callback, value)
	end
end

export type Signal<T> = {
	Connect: (self: Signal<T>, Hit: (T) -> ()) -> Connection,
	Once: (self: Signal<T>, Hit: (T) -> ()) -> Connection,
	Fire: (self: Signal<T>, value: T) -> (),
}

return Signal
