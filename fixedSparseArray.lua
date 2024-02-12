local isPosInt = _G.qtype.isPosInt
local floor, min = math.floor, math.min
local create, insert = table.create, table.insert

local fixedSparseArray = _G.qclass.extend("fixedSparseArray", "sparseArray")

fixedSparseArray:setField("_size", nil, true)

fixedSparseArray:overrideProperty(
    "size",
    function(inst)
        return inst._size
    end,
    function(inst, v)
        inst.base.size = v
    end
)

fixedSparseArray:overrideMethod("_increaseSize", function(inst)
    error("cannot change size of ".._G.qtype.get(inst))
end)

fixedSparseArray:overrideMethod("set", function(inst, index, value)
    if index < 1 or index > inst.size or index ~= floor(index) then
        error("bad index expected positive integer within array range")
    end
    local placeholder = inst._placeholder
    if value == nil then
        value = placeholder
    end
    local tab = inst._table
    if tab[index] ~= placeholder then
        insert(inst._holes, index)
    end
    tab[index] = value
end)

fixedSparseArray:overrideMethod("insert", function(inst, value)
    if inst.space == 0 then
        error(tostring(inst).." out of space")
    end
    if value == nil then
        error("bad type to value expected a non-nil type")
    end
    local index
    local holes = inst._holes
    local hole = holes[1]
    if hole then
        index = hole
    else
        index = inst._peakIndex + 1
    end
    local tab = inst._table
    if tab[index] ~= inst._placeholder then
        insert(holes, index)
    end
    tab[index] = value
    return index
end)

fixedSparseArray:overrideMethod("insertMul", function(inst, values)
    if type(values) ~= "table" then
        error("bad type to values expected table")
    end
    local valueCount = #values
    if valueCount > inst.space then
        print(valueCount, inst.space, inst.size)
        error(tostring(inst).." out of space")
    end
    local holes = inst._holes
    local holeCount = #holes
    local tab = inst._table
    local indices = {}
    for i = 1, min(holeCount, valueCount) do
        insert(indices, holes[i])
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
            insert(holes, insertIndex)
        end
        tab[insertIndex] = values[index]
    end
    return indices
end)

fixedSparseArray:setConstructor(function(inst, size)
    if not isPosInt(size) then
        error("bad type to size expected positive integer")
    end
    inst._size = size
    inst._table = create(size, inst._placeholder)
    inst._holes = {}
end)

fixedSparseArray:finalize()
return fixedSparseArray
