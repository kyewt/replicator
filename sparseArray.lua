local isPosInt = _G.qtype.isPosInt
local floor, min = math.floor, math.min
local create, insert, remove, sort, find = table.create, table.insert, table.remove, table.sort, table.find

local sparseArray = _G.qclass.extend("sparseArray")

sparseArray:setStaticField("_placeholder", {}, true)

sparseArray:setField("_table", nil, true)
sparseArray:setField("_holes", nil, true)
sparseArray:setField("_peakIndex", 0)

sparseArray:setProperty(
    "size",
    function(inst)
        return #inst._table
    end,
    function(inst)
        error("cannot set ".._G.qtype.get(inst)..".size")
    end
)

sparseArray:setProperty(
    "space",
    function(inst)
        return inst.size - inst._peakIndex + #inst._holes
    end,
    function(inst)
        error("cannot set ".._G.qtype.get(inst)..".space")
    end
)

sparseArray:setMethod("_increaseSize", function(inst, amount)
    if not isPosInt(amount) then
        error("bad type to amount expected positive integer")
    end
    local size = inst.size
    local tab = inst._table
    local placeholder = inst._placeholder
    for i = 1, amount do
        local index = size + i
        tab[index] = placeholder
    end
end)

sparseArray:setMethod("_sortHoles", function(inst)
    local sortFunc = function(a, b)
        return a < b
    end
    sort(inst._holes, sortFunc)
end)

sparseArray:setMethod("getAllValuesWithIndices", function(inst)
    local indices = inst.getAllIndicesWithoutHoles()
    local values = inst.getMul(indices)
    return values, indices
end)
sparseArray:setMethod("getAllIndicesWithoutHoles", function(inst)
    local indices = {}
    for i = 1, inst._peakIndex do
        insert(indices, i)
    end
    for _, hole in ipairs(inst._holes) do
        remove(indices, hole)
    end
    return indices
end)

sparseArray:setMethod("get", function(inst, index)
    local value = inst._table[index]
    if value == inst._placeholder then
        return nil
    end
    return value
end)

sparseArray:setMethod("getMul", function(inst, indices, holesPossible)
    local values = {}
    local tab = inst._table
    if not holesPossible then
        for _, index in ipairs(indices) do
            insert(values, tab[index])
        end
    else
        local placeholder = inst._placeholder
        for _, index in ipairs(indices) do
            local value = tab[index]
            if value == placeholder then
                continue
            end
            insert(values, value)
        end
    end
    return values
end)

sparseArray:setMethod("getAll", function(inst)
    local values = {}
    local tab = inst._table
    local indices = {}
    for i = 1, inst._peakIndex do
        insert(indices, i)
    end
    local holes = inst._holes
    for _, hole in ipairs(holes) do
        remove(indices, hole)
    end
    for _, index in ipairs(indices) do
        insert(values, tab[index])
    end
    return values
end)

sparseArray:setMethod("find", function(inst, value)
    for index, existingValue in ipairs(inst._table) do
        if existingValue == value then
            return index
        end
    end
    return nil
end)

sparseArray:setMethod("set", function(inst, index, value)
    if not isPosInt(index) then
        error("bad type to index expected positive integer")
    end
    local size = inst.size
    if index > size then
        local dif = index - size
        inst._increaseSize(dif)
    end
    local placeholder = inst._placeholder
    if value == nil then
        value = placeholder
    end
    local tab = inst._table
    if tab[index] ~= placeholder then
        insert(inst._holes, index)
        inst._sortHoles()
    end
    tab[index] = value
end)

sparseArray:setMethod("remove", function(inst, index)
    if not isPosInt(index) or index < 1 or index > inst.size then
        error("bad index expected positive integer within array range")
    end
    local tab = inst._table
    local placeholder = inst._placeholder
    local removed = false
    if tab[index] ~= placeholder then
        insert(inst._holes, index)
        inst._sortHoles()
        removed = true
    end
    tab[index] = placeholder
    return removed
end)

sparseArray:setMethod("removeMul", function(inst, indices)
    if type(indices) ~= "table" then
        error("bad type to indices expected table")
    end
    local indexCount = #indices
    local size = inst.size
    if indexCount > size then
        error("indices is larger than "..tostring(inst))
    end
    for _, removalIndex in ipairs(indices) do
        if not isPosInt(removalIndex) or removalIndex < 1 or removalIndex > size then
            error("bad index expected positive integer within array range")
        end
    end
    local tab = inst._table
    local placeholder = inst._placeholder
    local holes = inst._holes
    local removed = {}
    for _, removalIndex in ipairs(indices) do
        if tab[removalIndex] ~= placeholder then
            insert(removed, removalIndex)
            insert(holes, removalIndex)
        end
        tab[removalIndex] = placeholder
    end
    inst._sortHoles()
    return removed
end)

sparseArray:setMethod("insert", function(inst, value)
    if value == nil then
        error("bad type to value expected a non-nil type")
    end
    local index
    local tab = inst._table
    local holes = inst._holes
    if inst.space ~= 0 then
        local hole = holes[1]
        if hole then
            index = hole
        else
            index = inst._peakIndex + 1
        end
        if tab[index] ~= inst._placeholder then
            error("insert should only place in empty slots")
        end
    else
        inst._increaseSize(1)
        local size = inst.size
        index = size
        inst._peakIndex = size
    end
    local holeIndex = find(holes, index)
    if holeIndex then
        remove(holes, index)
    end
    tab[index] = value
    return index
end)

sparseArray:setMethod("insertMul", function(inst, values)
    if type(values) ~= "table" then
        error("bad type to values expected table")
    end
    local valueCount = #values
    local space = inst.space
    if valueCount > space then
        local overflow = valueCount - space
        local indicesNeeded = inst.size + overflow
        inst._increaseSize(indicesNeeded)
    end
    local holes = inst._holes
    local holeCount = #holes
    local tab = inst._table
    local indices = {}
    local filledHoleIndices = {}
    for i = 1, min(holeCount, valueCount) do
        insert(indices, holes[i])
        insert(filledHoleIndices, i)
    end
    if valueCount > holeCount then
        local peak = inst._peakIndex
        for i = holeCount + 1, valueCount do
            peak += 1
            insert(indices, peak)
        end
        inst._peakIndex = peak
    end
    local placeholder = inst._placeholder
    for index, insertIndex in ipairs(indices) do
        if tab[insertIndex] ~= placeholder then
            error("insert should only place in empty slots")
        end
        tab[insertIndex] = values[index]
    end
    if #filledHoleIndices ~= 0 then
        for _, holeIndex in ipairs(filledHoleIndices) do
            holes[holeIndex] = nil
        end
        inst._sortHoles()
    end
    return indices
end)

sparseArray:setMethod("print", function(inst)
    print(inst._table)
end)

sparseArray:setConstructor(function(inst, size)
    if size == nil then
        size = 0
    end
    if type(size) ~= "number" or size < 0 or size ~= floor(size) then
        error("bad size expected non-negative integer")
    end
    inst._table = create(size, inst._placeholder)
    inst._holes = {}
end)

sparseArray:finalize()
return sparseArray