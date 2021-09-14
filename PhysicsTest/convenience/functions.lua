function enum(a)
    local count = #a
    for i = 1, count do
        local e = a[i]
        a[e] = i
    end

    return a
end