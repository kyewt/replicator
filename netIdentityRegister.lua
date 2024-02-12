local isPosInt= _G.qtype.isPosInt
local fixedSparseArray = _G.classes.fixedSparseArray
local sparseArray = _G.classes.sparseArray
local insert = table.insert

local netIdentityRegister = _G.qclass.extend("netIdentityRegister")

netIdentityRegister:setStaticField("_placeholder", {}, true)

netIdentityRegister:setField("_mainArray", nil, true)
netIdentityRegister:setField("_defaultArraySize", 2000000)

netIdentityRegister:setField("destroying", nil, true)

netIdentityRegister:setMethod("getValue", function(inst, index)
    return inst._mainArray.get(index)
end)

netIdentityRegister:setMethod("getValues", function(inst, indices)
    local array = inst._mainArray
    local values = {}
    for _, index in ipairs(indices) do
        insert(values, array.get(index))
    end
    return values
end)

netIdentityRegister:setMethod("getPairsFromValues", function(inst, values)
    local foundIndices, foundValues = {}, {}
    local array = inst._mainArray
    for _, value in ipairs(values) do
        local index = array.find(value)
        insert(foundIndices, index)
        insert(foundValues, value)
    end
    return foundIndices, foundValues
end)

netIdentityRegister:setMethod("getAllValuesWithIndices", function(inst)
    return inst._mainArray.getAllValuesWithIndices()
end)

netIdentityRegister:setMethod("getAllIndicesWithoutHoles", function(inst)
    return inst._mainArray.getAllIndicesWithoutHoles()
end)

netIdentityRegister:setMethod("getIndex", function(inst, value)
    return inst._mainArray.find(value)
end)

netIdentityRegister:setMethod("getIndices", function(inst, values)
    local indices = {}
    local array = inst._mainArray
    for _, value in ipairs(values) do
        local index = array.find(value)
        if index then
            insert(indices, index)
        end
    end
    return indices
end)

netIdentityRegister:setMethod("registerValue", function(inst, value)
    return inst._mainArray.insert(value)
end)

netIdentityRegister:setMethod("registerValues", function(inst, values)
    return inst._mainArray.insertMul(values)
end)

netIdentityRegister:setMethod("registerValueAtIndex", function(inst, value, index)
    inst._mainArray.set(index, value)
end)

netIdentityRegister:setMethod("registerValuesAtIndices", function(inst, values, indices)
    if #values ~= #indices then
        error("size of values and indices is different")
    end
    local array = inst._mainArray
    for i = 1, #values do
        array.set(indices[i], values[i])
    end
end)

netIdentityRegister:setMethod("deregisterValue", function(inst, index)
    local removed = inst._mainArray.remove(index)
    if not removed then
        error("value did not exist at index "..tostring(index))
    end
end)

netIdentityRegister:setMethod("deregister", function(inst, indices)
    local removed = inst._mainArray.removeMul(indices)
    if #removed ~= #indices then
        error("values did not exist at some indices")
    end
end)

netIdentityRegister:setConstructor(function(inst, size)
    if size ~= nil then
        if not isPosInt(size) then error("bad type to size expected positive integer") end
    else
        size = inst._defaultArraySize
    end
    inst.destroying = Instance.new("BindableEvent")
    inst._mainArray = fixedSparseArray(size)
    inst._secondaryArrays = sparseArray()
end)

netIdentityRegister:setDestructor(function(inst)
    inst.destroying:Fire()
end)

netIdentityRegister:finalize()
return netIdentityRegister
