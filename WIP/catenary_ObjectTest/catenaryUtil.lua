function math.cosh(val)
    local exp = math.exp(val)
    local mathExp1 = ( (exp^val) - (exp^-val) ) / 2
    --sb.logInfo("mathExp1 %s", mathExp1)
    return mathExp1
end