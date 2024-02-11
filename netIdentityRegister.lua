local isPosInt = _G.qtype.isPosInt
local fixedSparseArray = _G.classes.fixedSparseArray
local insert = table.insert

local netIdentityRegister = _G.qclass.extend("netIdentityRegister")

netIdentityRegister:setStaticField("_placeholder", {}, true)

netIdentityRegister:setField("_mainArray", nil, true)
netIdentityRegister:setField("_secondaryArrays", nil, true)
netIdentityRegister:setField("_defaultArraySize", 2000000)

netIdentityRegister:setMethod("createSecondaryArray", function(inst, size)
    if size ~= nil then
        if not isPosInt(size) then error("bad type to size expected positive integer") end
    else
        size = inst._defaultArraySize
    end
    local secondaryArray = fixedSparseArray(size)
    return inst._secondaryArrays.insert(secondaryArray)
end)
netIdentityRegister:setMethod("deleteSecondaryArray", function(inst, index)
    local removed = inst._secondaryArrays.remove(index)
    if not removed then
        error("secondaryArray did not exist at index "..tostring(index))
    end
end)

netIdentityRegister:setMethod("getValue", function(inst, index, secondaryArrayIndex)
    local value = inst._mainArray.get(index)
    if not value and secondaryArrayIndex then
        value = inst._secondaryArrays.get(secondaryArrayIndex).get(index)
    end
    return value
end)

netIdentityRegister:setMethod("getValues", function(inst, indices, secondaryArrayIndex)
    local array = inst._mainArray
    local values = {}
    local value = array.get(indices[1])
    if value then
        insert(values, value)
        for i = 2, #indices do
            value = array.get(indices[i])
            insert(values, value)
        end
    else
        array = inst._secondaryArrays.get(secondaryArrayIndex)
        if not array then
            error("secondaryArray does not exist at index "..secondaryArrayIndex)
        end
        for _, index in ipairs(indices) do
            value = array.get(index)
            insert(values, value)
        end
    end
    if #values ~= #indices then
        error("some values were nil")
    end
    return values
end)

netIdentityRegister:setMethod("getIndex", function(inst, value, secondaryArrayIndex)
    local index = inst._mainArray.find(value)
    if index or not secondaryArrayIndex then
        return index
    end
    return inst._secondaryArrays.get(secondaryArrayIndex).find(value)
end)

netIdentityRegister:setMethod("getIndices", function(inst, values, secondaryArrayIndex)
    local array = inst._mainArray
    local indices = {}
    local index = array.find(values[1])
    if index then
        insert(indices, index)
        for i = 2, #values do
            index = array.find(values[i])
            insert(indices, index)
        end
    else
        array = inst._secondaryArrays.get(secondaryArrayIndex)
        if not array then
            error("secondaryArray does not exist at index "..secondaryArrayIndex)
        end
        for _, value in ipairs(values) do
            index = array.find(value)
            insert(indices, index)
        end
    end
    if #indices ~= #values then
        error("some indices were nil")
    end
    return indices
end)

netIdentityRegister:setMethod("registerValue", function(inst, value)
    return inst._mainArray.insert(value)
end)

netIdentityRegister:setMethod("registerValues", function(inst, values)
    return inst._mainArray.insertMul(values)
end)

netIdentityRegister:setMethod("deregisterValue", function(inst, index)
    local removed = inst._main.remove(index)
    if not removed then
        error("value did not exist at index "..tostring(index))
    end
end)

netIdentityRegister:setMethod("deregisterValues", function(inst, indices)
    local removed = inst._main.removeMul(indices)
    if #removed ~= #indices then
        for _, removedIndex in ipairs(removed) do
            table.remove(indices, table.find(indices, removedIndex))
        end
        error("values did not exist at indices "..indices)
    end
end)

netIdentityRegister:setMethod("registerSecondaryValue", function(inst, arrayIndex, value)
    return inst._secondaryArrays.get(arrayIndex).insert(value)
end)

netIdentityRegister:setMethod("registerSecondaryValues", function(inst, arrayIndex, values)
    return inst._secondaryArrays.get(arrayIndex).insertMul(values)
end)

netIdentityRegister:setMethod("deregisterSecondaryValue", function(inst, arrayIndex, index)
    local array = inst._secondaryArrays.get(arrayIndex)
    if not array then
        error("secondaryArray does not exist at index "..arrayIndex)
    end
    local removed = array.remove(index)
    if not removed then
        error("value did not exist at index "..tostring(index))
    end
end)

netIdentityRegister:setMethod("deregisterSecondaryValues", function(inst, arrayIndex, indices)
    local array = inst._secondaryArrays.get(arrayIndex)
    if not array then
        error("secondaryArray does not exist at index "..arrayIndex)
    end
    local removed = array.removeMul(indices)
    if #removed ~= #indices then
        for _, removedIndex in ipairs(removed) do
            table.remove(indices, table.find(indices, removedIndex))
        end
        error("values did not exist at indices "..indices)
    end
end)

netIdentityRegister:setConstructor(function(inst, size, maximumSecondaryArrays)
    if size ~= nil then
        if not isPosInt(size) then error("bad type to size expected positive integer") end
    else
        size = inst._defaultArraySize
    end
    if maximumSecondaryArrays ~= nil then
        if not isPosInt(maximumSecondaryArrays) then
            error("bad type to maximumSecondaryArrays expected positive integer")
        end
    else
        maximumSecondaryArrays = 12
    end
    inst._mainArray = fixedSparseArray(size)
    inst._secondaryArrays = fixedSparseArray(maximumSecondaryArrays)
end)

netIdentityRegister:finalize()
return netIdentityRegister
