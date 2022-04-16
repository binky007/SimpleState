--// Imports
local HttpService = game:GetService("HttpService")


--// Local functions
local function RecurseSet(t,k,v,mt,i)
	for _k, _v in pairs(v) do
		if type(_v) == "table" then
			t[k][_k] = RecurseSet(v,_k,_v,mt,i)
		else
			if mt.ProtectTyping and type(t[k][_k]) == type(_v) or not mt.ProtectTyping then
				t[k][_k] = _v
				if not i and mt._Events[k] then
					local Events = mt._Events
					script[Events[k].uuid]:Fire(v,_v)
				end
			else
				warn("Mismatched typing")
			end
		end
	end
	return v
end

local function deepFreeze(t)
	table.freeze(t)
	for _, v in pairs(t) do
		if type(v) == "table" then
			deepFreeze(v)
		end
	end
end

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

local function createChangedSignal(t,k)
	local uuid = HttpService:GenerateGUID(false)
	local Remote = Instance.new("BindableEvent")
	Remote.Name = uuid
	Remote.Parent = script
	local Data = {
		uuid = uuid,
		Event = Remote.Event
	}
	t[k] = Data
	return Data.Event
end

--// Module functions
local SimpleState = {}
SimpleState.__index = SimpleState

SimpleState.new = function(props)
	local uuid = HttpService:GenerateGUID(false)
	local Remote = Instance.new("BindableEvent")
	Remote.Name = uuid
	Remote.Parent = script
	local Data = {
		_Data = props,
		_Initial = deepCopy(props),
		_uuid = uuid,
		_Events = {},
		ProtectTyping = false,
	}
	return setmetatable(Data, SimpleState)
end

function SimpleState:SetState(k,v,i)
	
	if type(v) == "table" then
		RecurseSet(self._Data, k,v, self,i)
	else
		if self.ProtectTyping and type(self._Data[k]) == type(v) or not self.ProtectTyping then
			if not i and self._Events[k] then
				script[self._Events[k].uuid]:Fire(self._Data[k], v)
			end
			self._Data[k] = v
		else
			warn("Mismatched typing")
		end
		
	end
	
end

function SimpleState:Get(k,d)
	local Value = self._Data[k]
	return type(Value) == "table" and deepCopy(self._Data) or Value or d
end

function SimpleState:GetState()
	return deepCopy(self._Data)
end

function SimpleState:Reset()
	self._Data = deepCopy(self._Initital)
end

function SimpleState:Toggle(k)
	local v = self._Data[k]
	if type(v) == "boolean" then
		v = not v
	else
		warn("Not Bool")
	end
end

function SimpleState:Increment(k,v,c)
	local _v = self._Data[k]
	self._Data[k] = type(_v) == "number" and math.min(_v+v, c) or _v
	if _v ~= self._Data[k] and self._Events[k] then
		script[self._Events[k].uuid]:Fire(self._Data[k], v)
	end
end

function SimpleState:Decrement(k,v,c)
	local _v = self._Data[k]
	self._Data[k] = type(_v) == "number" and math.max(_v-v, c) or _v
	if _v ~= self._Data[k] and self._Events[k] then
		script[self._Events[k].uuid]:Fire(self._Data[k], v)
	end
end

function SimpleState:GetChangedSignal(k)
	return self._Events[k] or createChangedSignal(self._Events,k)
end

return SimpleState
