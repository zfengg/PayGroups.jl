module PayGroups

using Dates

export Bill, Member, PayGroup
export print_member, print_bill, print_soln, print_meta_info,
    print_bill_today, print_member_today, print_billbyname
export add_bills!, add_member!, rm_bill!, rm_member!, ch_bill!, ch_member!
export igroupay, cmd_flow, gen_paygrp

# ---------------------------------- structs --------------------------------- #
"""
    `Bill` struct in the group
"""
mutable struct Bill
    billname::String
    date::Date
    total::Float64
    isAA::Bool
    paidBy::String
    shouldPay::Dict{String,Float64}
    Bill(bill::Bill) = new(bill.billname, bill.date, bill.total, bill.isAA, bill.paidBy, Dict())
    Bill(bn::String, d::Date) = new(bn, d, NaN, true, "", Dict())
end

"""
    `Member` struct in the group
"""
mutable struct Member
    name::String
    shouldPay::Dict{Date,Dict{String}{Float64}}
    hasPaid::Dict{Date,Dict{String}{Float64}}
    Member(m::String) = new(m, Dict(), Dict())
end

"""
    PayGroup

The object contains all the information about group payment.
"""
mutable struct PayGroup
    title::String
    members::Dict{String,Member}
    bills::Dict{Date,Dict{String,Bill}}
    PayGroup(title::String) = new(title, Dict(), Dict())
end

# ------------------------------------ get ----------------------------------- #
get_haspaid(m::Member, d::Date) = haskey(m.hasPaid, d) ? sum(values(m.hasPaid[d])) : 0.0
get_haspaid(m::Member, d) = get_haspaid(m, Date(d))
get_haspaid(g::PayGroup, m::String, d) = get_haspaid(g.members[m], d)
get_haspaid(m::Member) = isempty(m.hasPaid) ? 0.0 : sum(v for d in keys(m.hasPaid) for v in values(m.hasPaid[d]))

get_shouldpay(m::Member, d::Date) = haskey(m.shouldPay, d) ? sum(values(m.shouldPay[d])) : 0.0
get_shouldpay(m::Member, d) = get_shouldpay(m, Date(d))
get_shouldpay(g::PayGroup, m::String, d) = get_shouldpay(g.members[m], d)
get_shouldpay(m::Member) = isempty(m.shouldPay) ? 0.0 : sum(v for d in keys(m.shouldPay) for v in values(m.shouldPay[d]))

get_topay(m::Member, d::Date) = get_shouldpay(m, d) - get_haspaid(m, d)
get_topay(m::Member, d) = get_topay(m, Date(d))
get_topay(g::PayGroup, m::String, d) = get_shouldpay(g, m, d) - get_haspaid(g, m, d)
get_topay(m::Member) = get_shouldpay(m) - get_haspaid(m)

get_total(g::PayGroup, d::Date) = haskey(g.bills, d) ? sum(b.total for b in values(g.bills[d])) : 0.0
get_total(g::PayGroup, d) = get_total(g, Date(d))

# -------------------------- push_bill! & pop_bill! -------------------------- #
function push_bill!(g::PayGroup, b::Bill)
    # bills
    if haskey(g.bills, b.date)
        push!(g.bills[b.date], b.billname => b)
    else
        push!(g.bills, b.date => Dict(b.billname => b))
    end
    # hasPaid
    if haskey(g.members[b.paidBy].hasPaid, b.date)
        push!(g.members[b.paidBy].hasPaid[b.date], b.billname => b.total)
    else
        push!(g.members[b.paidBy].hasPaid, b.date => Dict(b.billname => b.total))
    end
    # shouldPay
    for (m, v) in b.shouldPay
        if haskey(g.members[m].shouldPay, b.date)
            push!(g.members[m].shouldPay[b.date], b.billname => v)
        else
            push!(g.members[m].shouldPay, b.date => Dict(b.billname => v))
        end
    end
    return g
end

function pop_bill!(g::PayGroup, b::Bill)
    if haskey(g.bills, b.date) && haskey(g.bills[b.date], b.billname)
        pop!(g.bills[b.date], b.billname)
        if isempty(g.bills[b.date])
            pop!(g.bills, b.date)
        end
        # hasPaid
        pop!(g.members[b.paidBy].hasPaid[b.date], b.billname)
        if isempty(g.members[b.paidBy].hasPaid[b.date])
            pop!(g.members[b.paidBy].hasPaid, b.date)
        end
        # shouldPay
        for m in keys(b.shouldPay)
            pop!(g.members[m].shouldPay[b.date], b.billname)
            if isempty(g.members[m].shouldPay[b.date])
                pop!(g.members[m].shouldPay, b.date)
            end
        end
    end
    return g
end

# ----------------------------------- print ---------------------------------- #
const COLORS = Dict(
    :red => "\033[31m",
    :green => "\033[32m",
    # :yellow => "\033[33m",
    # :blue => "\033[34m]",
    # :magenta => "\033[35m",
    # :cyan => "\033[36m",
    # :lightred => "\033[91m",
    # :lightgreen => "\033[92m",
    # :lightyellow => "\033[93m",
    # :lightblue => "\033[94m]",
    # :lightmagenta => "\033[95m",
    # :lightcyan => "\033[96m",
    :nc => "\033[0m",
    :banner => "\033[32m",
    :group => "\033[31m",
    :member => "\033[96m",
    :bill => "\033[93m",
    :aa => "\033[34m",
    :total => "\033[32m",
    :remaintopay => "\033[35m",
    :date => "\033[4m",
    :soln => "\033[32m",
    :cmd => "\033[32m",
    :congrats => "\033[96m",
    :manual => "\033[35m",
    :path => "\033[32m",
    :tip => "\033[32m",
    :warning => "\033[33m",
    :error => "\033[31m",
    :danger => "\033[31m",
)
colorstring(s, c::Symbol) = COLORS[c] * s * "\033[0m"

# print errors
function print_invalid_date(d)
    println(colorstring("Invalid DateFormat: ", :error), colorstring("$d", :date), " is not a valid date format!")
    println("Please input date like ", colorstring("$(today())", :tip))
end

print_not_member(m::String) = println("Sorry, ", colorstring(m, :member), " is not in your group!")

print_member_tip(m::String, t::Float64) = println(colorstring(m, :member), " : ", t)

function hasbill(g::PayGroup, bn::String, d::Date = today())
    if !haskey(g.bills, d)
        println("No bills on ", colorstring("$d", :date))
        return false
    end
    if !haskey(g.bills[d], bn)
        println("No bill with name ", colorstring(bn, :bill), " on ", colorstring("$d", :date))
        return false
    end
    return true
end

# print member
"""
    print_member(m::Member, d::Date)

Print payment information of `m` on `d`.
"""
function print_member(m::Member, d::Date, showName::Bool = true)
    if showName
        println("[", colorstring(m.name, :member), "]")
    end
    flagHasPaid = haskey(m.hasPaid, d)
    flagShouldPay = haskey(m.shouldPay, d)

    if (!flagHasPaid) && (!flagShouldPay)
        println()
        return nothing
    end
    println(colorstring("$d", :date))

    if flagHasPaid
        println("-- has paid")
        for (k, v) in m.hasPaid[d]
            println(colorstring(k, :bill), " : ", v)
        end
        println("total = ", colorstring("$(get_haspaid(m, d))", :green))
    end
    if flagShouldPay
        println("-- should pay")
        for (k, v) in m.shouldPay[d]
            println(colorstring(k, :bill), " : ", v)
        end
        println("total = ", colorstring("$(get_shouldpay(m, d))", :red))
    end
    println("-- remains to pay: ", colorstring("$(get_topay(m, d))", :remaintopay), "\n")
    return nothing
end

function print_member(m::Member, d, showName::Bool = true)
    try
        print_member(m, Date(d), showName)
    catch
        print_invalid_date(d)
    end
end
function print_member(m::Member)
    println("[", colorstring(m.name, :member), "]")
    dates = union([x[1] for x in m.hasPaid], [y[1] for y in m.shouldPay])
    for d in dates
        print_member(m, d, false)
    end
end

"""
    print_member(g::PayGroup)

Print payment information for all the members in `g`.
"""
function print_member(g::PayGroup)
    println("\n======\n")
    for m in values(g.members)
        print_member(m)
        println()
    end
    println("======\n")
end

print_member(g::PayGroup, m::String, d::Date) = haskey(g.members, m) ? print_member(g.members[m], d) : print_not_member(m)
function print_member(g::PayGroup, m::String, d)
    try
        print_member(g::PayGroup, m, Date(d))
    catch
        print_invalid_date(d)
    end
end
print_member(g::PayGroup, m::String) = haskey(g.members, m) ? print_member(g.members[m]) : print_not_member(m)

print_member_today(m::Member) = print_member(m, today())
print_member_today(g::PayGroup, m::String) = haskey(g.members, m) ? print_member_today(g.members[m]) : print_not_member(m)
function print_member_today(g::PayGroup)
    for m in values(g.members)
        print_member_today(m)
        println()
    end
end

# print meta
"""
    print_meta_info(g::PayGroup)

Show meta information of a group.
"""
function print_meta_info(g::PayGroup)
    println("Group: ", colorstring(g.title, :group))
    print("Members: $(COLORS[:member])")
    for m in keys(g.members)
        print(m, " ")
    end
    print("$(COLORS[:nc])\n")
    if !isempty(g.bills)
        println("Total: $(COLORS[:total])", sum(b.total for d in keys(g.bills) for b in values(g.bills[d])), "$(COLORS[:nc])")
    end
end

function print_meta_members(g::PayGroup)
    if isempty(g.members)
        println("No members yet!")
        return nothing
    end
    for m in keys(g.members)
        println(colorstring(m, :member))
    end
end

function print_meta_bills(g::PayGroup)
    if isempty(g.bills)
        println("No bills yet!")
        return nothing
    end
    for (d, dateBills) in g.bills
        println(colorstring("$d", :date))
        for bn in keys(dateBills)
            println(colorstring(bn, :bill))
        end
    end
end

# print bill
"""
    print_bill(bill::Bill)

Print the information of bills.
"""
function print_bill(b::Bill)
    println("[", colorstring(b.billname, :bill), "]")
    println("total = ", colorstring("$(b.total)", :total), " paid by ", colorstring(b.paidBy, :member), ";")
    if b.isAA
        println("-- ", colorstring("AA", :aa), " --")
    else
        println("-- ", colorstring("not AA", :aa), " --")
    end
    for (k, v) in b.shouldPay
        println(colorstring(k, :member), " => ", v)
    end
end
function print_bill(g::PayGroup, d::Date)
    if !haskey(g.bills, d)
        println(colorstring("$d", :date), " has ", colorstring("no bills", :warning))
        return nothing
    end
    println(colorstring("$d", :date), " total: ", colorstring("$(get_total(g, d))", :total))
    for b in values(g.bills[d])
        print_bill(b)
        println()
    end
end
function print_bill(g::PayGroup, d)
    try
        print_bill(g, Date(d))
    catch
        print_invalid_date(d)
    end
end

"""
    print_bill(g::PayGroup)

Show all the bills in `g::PayGroup`.
"""
function print_bill(g::PayGroup)
    println("\n======\n")
    # print_meta_info(g)
    println()
    for d in keys(g.bills)
        print_bill(g, d)
        println()
    end
    println("======\n")
end


function print_bill(g::PayGroup, bn::String, d::Date)
    if hasbill(g, bn, d)
        println(colorstring("$d", :date))
        print_bill(g.bills[d][bn])
    end
end
function print_bill(g::PayGroup, s::String, d)
    try
        print_bill(g, s, Date(d))
    catch
        print_invalid_date(d)
    end
end

print_bill_today(g::PayGroup) = print_bill(g, today())
print_bill_today(g::PayGroup, bn::String) = print_bill(g, bn, today())

function print_billbyname(g::PayGroup, bn::String)
    hasBill = false
    for d in keys(g.bills)
        if haskey(g.bills[d], bn)
            hasBill = true
            println(colorstring("$d", :date))
            print_bill(g.bills[d][bn])
            println()
        end
    end
    hasBill || println("Oops, ", colorstring(bn, :bill), " is not your bill!")
end

"""
show the payment solution.
"""
function print_soln(soln)
    println("\nTada! Here is a ", colorstring("payment solution", :soln), " :)\n")
    if soln[1][3] == 0
        println(colorstring(" Congrats! Everyone is happy. ", :congrats))
    else
        for tuple in soln
            println(colorstring(tuple[1], :member), " => ", colorstring(tuple[2], :member), " : ", tuple[3])
        end
    end
    println()
end

# ------------------------------------ gen ----------------------------------- #
"""
    gen_paygrp() -> payGrp::PayGroup

Generate a `PayGroup` interactively.
"""
function gen_paygrp()
    println("What's the name of your group?")
    title = readline() |> strip |> String
    while isempty(title)
        println("Why not name your group? ^o^")
        println("Please give it a nice name:")
        title = readline() |> strip |> String
    end
    payGrp = PayGroup(title)
    println("And who are in the group ", colorstring(title, :group), "?")
    members = String[]
    while true
        membersTmp = readline()
        append!(members, split(membersTmp))
        unique!(members)
        println()
        println("Your group now contains ", colorstring("$(length(members))", :tip), " members:")
        for x in members
            println(colorstring(x, :member))
        end
        println()
        println("Do you want to add more members?(y/[n])")
        flagInputName = readline()
        if flagInputName == "y"
            println()
            println("Please add the names of the others:")
        elseif length(members) == 0
            println()
            println("haha~ such a joke that a group with ", colorstring("NO", :warning), " members!")
            println("Please add the names of the others:")
        else
            if length(members) == 1
                println("Oh~ You are the only one in the group.")
                println("Good, we will accompany you. ^_^")
            end
            break
        end
    end
    for name in members
        push!(payGrp.members, name => Member(name))
    end
    return payGrp
end

# ----------------------------------- read ----------------------------------- #
function read_nonempty_string()
    s = readline() |> strip |> String
    while isempty(s)
        println(colorstring("Empty", :warning), " string is not good.")
        s = readline() |> strip |> String
    end
    return s
end

function read_valid_money()
    x = undef
    while true
        try
            tmpExpr = Meta.parse(readline())
            x = eval(tmpExpr) |> Float64
            println(tmpExpr, " = ", x)
            break
        catch
            print("Oops, ", colorstring("invalid", :error), " money input! ")
            print("Please input a ", colorstring("number", :tip), " or ", colorstring("math-expression", :tip), ":\n")
        end
    end
    return x
end

function read_valid_member(g::PayGroup)
    m = undef
    while true
        m = readline()
        m = strip(m)
        if m in keys(g.members)
            break
        else
            println("Oops, ", colorstring(m, :member), " is not in your group! Please input the name again:")
        end
    end
    return m
end

# ------------------------------------ ch ------------------------------------ #
function ch_bill!(g::PayGroup, bn::String, d::Date = today())
    if !hasbill(g, bn, d)
        return nothing
    end

    oldBill = g.bills[d][bn]
    println("The following bill will be changed:")
    print_bill(oldBill)


    println("\nChange the bill ", colorstring("name", :tip), "?([y]/n)")
    shouldChName = readline()
    if shouldChName != "n"
        println("What's the new bill name?")
        newBillname = undef
        while true
            newBillname = read_nonempty_string()
            newBillname = split(newBillname)[1] |> String
            if !haskey(g.bills[d], newBillname)
                break
            end
            println(colorstring(newBillname, :bill), " already exists on ", colorstring("$d", :date))
            prinlln("Please input again:")
        end
        println("New name: ", colorstring(newBillname, :bill))
    end

    println("Change the ", colorstring("payment", :tip), " details?([y]/n)")
    shouldChDetails = readline()
    if shouldChDetails == "n"
        if shouldChName == "n"
            return nothing
        end
        pop_bill!(g, oldBill)
        oldBill.billname = newBillname
        push_bill!(g, oldBill)

        println()
        print_bill(oldBill)
        return g
    end

    # get details
    if length(g.members) == 1
        println("How much do you paid for ", colorstring(tmpBillname, :bill), "?")
        payTotal = read_valid_money()
        if shouldChName == "n"
            g.members[oldBill.paidBy].hasPaid[d][bn] = payTotal
            g.members[oldBill.paidBy].shouldPay[d][bn] = payTotal
            g.bills[d][bn].total = payTotal
            return g
        end
        pop_bill!(g, oldBill)
        oldBill.total = payTotal
        oldBill.billname = newBillname
        push_bill!(g, oldBill)

        println()
        print_bill(oldBill)
        return g
    end

    # more members mode
    if shouldChName == "n"
        newBillname = bn
    end
    newBill = Bill(newBillname, d)

    println("Who pays ", colorstring(newBillname, :bill), "?")
    payMan = read_valid_member(g)
    newBill.paidBy = payMan

    println("And how much has ", colorstring(payMan, :member), " paid?")
    payTotal = read_valid_money()
    newBill.total = payTotal

    # payment details
    println("Do you ", colorstring("AA", :aa), "?([y]/n)")
    isAA = readline()
    if isAA == "n"
        isAA = false
        newBill.isAA = isAA

        tmpBill = undef
        while true
            tmpBill = Bill(newBill)
            println("How much should each member pay? (", colorstring("j", :tip), " to jump)")
            for m in keys(g.members)
                tmpShouldPay = undef
                while true
                    print(colorstring(m, :member), " : ")
                    try
                        tmpInput = readline()
                        if tmpInput in ("", "j")
                            break
                        end
                        tempExpr = Meta.parse(tmpInput)
                        tmpShouldPay = eval(tempExpr) |> Float64
                        println(tempExpr, " = ", tmpShouldPay)
                        break
                    catch
                        println(colorstring("Invalid", :error), " number expression!")
                    end
                end
                tmpShouldPay != undef && push!(tmpBill.shouldPay, m => tmpShouldPay)
            end

            tmpSum = sum(values(tmpBill.shouldPay))
            if tmpBill.total != tmpSum
                println("\nOops! Sum=", colorstring("$tmpSum", :error), " does not match Total=",
                    colorstring("$(tmpBill.total)", :warning), "\n")
                tmpTip = tmpBill.total - tmpSum
                if tmpTip < 0
                    continue
                end
                tmpTipPercents = 100 * round(tmpTip / tmpSum, digits = 3)
                println("Is Total - Sum = ", colorstring("$tmpTip ($tmpTipPercents %)", :tip), " your tip?([y]/n)")
                a = readline()
                if a != "n"
                    tmpNumShouldPay = length(tmpBill.shouldPay)
                    println(colorstring("Tips", :tip), " for each member:")
                    accumTip = 0
                    countMemberTip = 0
                    for (m, v) in tmpBill.shouldPay
                        countMemberTip += 1
                        tmpMemberTip = tmpTip * v / tmpSum
                        if countMemberTip == tmpNumShouldPay
                            tmpMemberTip = tmpTip - accumTip
                        end
                        tmpBill.shouldPay[m] += tmpMemberTip
                        accumTip += tmpMemberTip
                        print_member_tip(m, tmpMemberTip)
                    end
                    if sum(values(tmpBill.shouldPay)) == tmpBill.total
                        newBill = tmpBill
                        break
                    else
                        println("Rounding error exits!")
                    end
                end
            else
                newBill = tmpBill
                break
            end
        end

    else
        isAA = true
        newBill.isAA = isAA

        println(colorstring("AA", :aa), " on all the members?([y]/n)")
        isAllAA = readline()
        AAlist = []
        if isAllAA == "n"
            while true
                println("Check [y]/n ?")
                for m in keys(g.members)
                    print(colorstring(m, :member), " : ")
                    tmpIsAA = readline()
                    if tmpIsAA != "n"
                        push!(AAlist, m)
                    end
                end
                if !isempty(AAlist)
                    break
                end
                println(colorstring("Oops!", :error), " No one is ", colorstring("AA", :aa), "!")
                println()
            end
        else
            AAlist = keys(g.members)
        end

        avgPay = newBill.total / length(AAlist)
        for m in AAlist
            push!(newBill.shouldPay, m => avgPay)
        end
    end

    pop_bill!(g, oldBill)
    push_bill!(g, newBill)

    println()
    print_bill(newBill)
    return g
end
function ch_bill_cmd!(g::PayGroup, bn::String, d)
    try
        ch_bill!(g::PayGroup, bn::String, Date(d))
    catch
        print_invalid_date(d)
    end
end

function ch_member!(g::PayGroup, m::String, nn::String)
    if !haskey(g.members, m)
        print_not_member(m)
        return nothing
    end
    if m == nn
        println("The same name. Nothing changed!")
        return nothing
    end
    member = g.members[m]
    member.name = nn
    for d in keys(member.hasPaid)
        for bn in keys(member.hasPaid[d])
            g.bills[d][bn].paidBy = nn
        end
    end
    for d in keys(member.shouldPay)
        for bn in keys(member.shouldPay[d])
            push!(g.bills[d][bn].shouldPay, nn => member.shouldPay[d][bn])
            pop!(g.bills[d][bn].shouldPay, m)
        end
    end
    pop!(g.members, m)
    push!(g.members, nn => member)
    println("Changed name of member ", colorstring(m, :member), " => ", colorstring(nn, :member))
end

# ------------------------------------ rm ------------------------------------ #
function rm_bill!(g::PayGroup, bn::String, d::Date = today())
    if !hasbill(g, bn, d)
        return nothing
    end
    println("The following bill will be ", colorstring("removed", :danger), ":")
    print_bill(g.bills[d][bn])
    println("\nAre you sure?(y/[n])")
    a = readline()
    if a == "y"
        pop_bill!(g, g.bills[d][bn])
        println(colorstring(bn, :bill), " has been removed!")
        return g
    end
    return g
end
function rm_bill_cmd!(g::PayGroup, bn::String, d)
    try
        rm_bill!(g::PayGroup, bn::String, Date(d))
    catch
        print_invalid_date(d)
    end
end

function rm_member!(g::PayGroup, m::String)
    # TODO: remove the member
end

# ------------------------------------ add ----------------------------------- #
"""
    add_member!(x::PayGroup) -> x::PayGroup

Add more members to a `PayGroup` interactively.
"""
function add_member!(g::PayGroup)
    println("Current members in ", colorstring(g.title, :group), ":")
    for m in keys(g.members)
        println(colorstring(m, :member))
    end
    # println("\n(", colorstring("Warning:", :warning), " Repeated names may crash the whole process!)\n")
    println("\nWho else do you want to add?")
    addMembers = String[]
    while true
        membersTmp = readline()
        append!(addMembers, split(membersTmp))
        unique!(addMembers)
        println()
        println("The following ", colorstring("$(length(addMembers))", :tip), " members will be added:")
        for m in addMembers
            println(colorstring(m, :member))
        end
        println()
        println("Do you what to add more members?(y/[n])")
        flagInputName = readline()
        if flagInputName == "y"
            println()
            println("Please add the names of the others:")
        else
            break
        end
    end

    for name in addMembers
        if haskey(g.members, name)
            println(colorstring(name, :member), " already in the group.")
            continue
        end
        push!(g.members, name => Member(name))
    end

    println("\nUpdated members in ", colorstring(g.title, :group), ":")
    for x in keys(g.members)
        println(colorstring(x, :member))
    end

    return g
end


"""
    add_bills!(payGrp::PayGroup, insertDate::Date) -> payGrp::PayGroup

Add bills on `insertDate` to `payGrp`.
"""
function add_bills!(payGrp::PayGroup, insertDate::Date)
    isToday = isequal(insertDate, today())
    println()

    if length(payGrp.members) == 1
        println("Ok, nice to meet you!")
        payMan = undef
        for x in keys(payGrp.members)
            println(colorstring(x, :member))
            payMan = x
        end

        if !isempty(payGrp.bills)
            println("And you have added the following bills:")
            print_meta_bills(payGrp)
            println("\nWhat's your next bill to add", isToday ? "" : " on " * colorstring("$insertDate", :date), "?")
        else
            println("Then let's review your bills together.")
            println("\nWhat's your first bill to add", isToday ? "" : " on " * colorstring("$insertDate", :date), "?")
        end

        while true
            # meta info
            billname = strip(readline()) |> String
            while isempty(billname)
                println("Please name your bill:")
                billname = strip(readline()) |> String
            end
            billname = split(billname)[1] |> String
            if haskey(payGrp.bills, insertDate) && haskey(payGrp.bills[insertDate], billname)
                for m in values(payGrp.members)
                    if haskey(m.hasPaid, insertDate) && haskey(m.hasPaid[insertDate], billname)
                        pop!(m.hasPaid[insertDate], billname)
                        if isempty(m.hasPaid[insertDate])
                            pop!(m.hasPaid, insertDate)
                        end
                    end
                    if haskey(m.shouldPay, insertDate) && haskey(m.shouldPay[insertDate], billname)
                        pop!(m.shouldPay[insertDate], billname)
                        if isempty(m.shouldPay[insertDate])
                            pop!(m.shouldPay, insertDate)
                        end
                    end
                end
            end
            bill = Bill(billname, insertDate)

            println("And how much have you paid for ", colorstring(billname, :bill), "?")
            payTotal = undef
            while true
                try
                    tempExpr = Meta.parse(readline())
                    payTotal = eval(tempExpr) |> Float64
                    println(tempExpr, " = ", payTotal)
                    break
                catch
                    print("Oops, ", colorstring("invalid", :error), " money input! ")
                    print("Please input a ", colorstring("number", :tip), " or ", colorstring("math-expression", :tip), ":\n")
                end
            end
            tmpMemHasPaid = payGrp.members[payMan].hasPaid
            if haskey(tmpMemHasPaid, insertDate)
                push!(tmpMemHasPaid[insertDate], billname => payTotal)
            else
                push!(tmpMemHasPaid, insertDate => Dict(billname => payTotal))
            end
            bill.total = payTotal
            bill.isAA = true
            bill.paidBy = payMan
            push!(bill.shouldPay, bill.paidBy => bill.total)
            tmpMemShouldPay = payGrp.members[payMan].shouldPay
            if haskey(tmpMemShouldPay, insertDate)
                push!(tmpMemShouldPay[insertDate], billname => payTotal)
            else
                push!(tmpMemShouldPay, insertDate => Dict(billname => payTotal))
            end

            if haskey(payGrp.bills, insertDate)
                push!(payGrp.bills[insertDate], billname => bill)
            else
                push!(payGrp.bills, insertDate => Dict(billname => bill))
            end

            println()
            print_bill(bill)

            println()
            println("And do you have another bill?([y]/n)")
            hasNextBill = readline()
            if hasNextBill == "n"
                break
            else
                println()
                println("(", colorstring("Tip:", :tip), " Overwrite ", colorstring("any", :tip), " previous bill by inputting the same name.)\n")
                println("What's your next bill?")
            end
        end
        return payGrp
    end

    println("Ok, nice to meet you all!")
    for x in keys(payGrp.members)
        println(colorstring(x, :member))
    end
    if !isempty(payGrp.bills)
        println("And you have added the following bills:")
        print_meta_bills(payGrp)
        println("\nWhat's your next bill to add", isToday ? "" : " on " * colorstring("$insertDate", :date), "?")
    else
        println("Then let's review your bills together.")
        println("\nWhat's your first bill to add", isToday ? "" : " on " * colorstring("$insertDate", :date), "?")
    end

    while true
        # meta info
        billname = strip(readline()) |> String
        while isempty(billname)
            println("Please name your bill:")
            billname = strip(readline()) |> String
        end
        billname = split(billname)[1] |> String
        if haskey(payGrp.bills, insertDate) && haskey(payGrp.bills[insertDate], billname)
            for m in values(payGrp.members)
                if haskey(m.hasPaid, insertDate) && haskey(m.hasPaid[insertDate], billname)
                    pop!(m.hasPaid[insertDate], billname)
                    if isempty(m.hasPaid[insertDate])
                        pop!(m.hasPaid, insertDate)
                    end
                end
                if haskey(m.shouldPay, insertDate) && haskey(m.shouldPay[insertDate], billname)
                    pop!(m.shouldPay[insertDate], billname)
                    if isempty(m.shouldPay[insertDate])
                        pop!(m.shouldPay, insertDate)
                    end
                end
            end
        end
        bill = Bill(billname, insertDate)

        println("Who pays ", colorstring(billname, :bill), "?")
        payMan = undef
        while true
            # payMan = split(readline())[1] |> String
            payMan = strip(readline()) |> String
            if payMan in keys(payGrp.members)
                break
            else
                println("Oops, ", colorstring(payMan, :member), " is not in your group! Please input the name again:")
            end
        end
        bill.paidBy = payMan

        println("And how much has ", colorstring(payMan, :member), " paid?")
        payTotal = undef
        while true
            try
                tempExpr = Meta.parse(readline())
                payTotal = eval(tempExpr) |> Float64
                println(tempExpr, " = ", payTotal)
                break
            catch
                print("Oops, ", colorstring("invalid", :error), " money input! ")
                print("Please input a ", colorstring("number", :tip), " or ", colorstring("math-expression", :tip), ":\n")
            end
        end
        tmpMemHasPaid = payGrp.members[payMan].hasPaid
        if haskey(tmpMemHasPaid, insertDate)
            push!(tmpMemHasPaid[insertDate], billname => payTotal)
        else
            push!(tmpMemHasPaid, insertDate => Dict(billname => payTotal))
        end
        bill.total = payTotal

        # details
        println("Do you ", colorstring("AA", :aa), "?([y]/n)")
        isAA = readline()
        if isAA == "n"
            isAA = false
            bill.isAA = isAA

            tmpBill = undef
            while true
                tmpBill = Bill(bill)
                println("How much should each member pay? (", colorstring("j", :tip), " to jump)")
                for name in keys(payGrp.members)
                    print(colorstring(name, :member), " : ")
                    tmpShouldPay = undef
                    while true
                        try
                            tmpInput = readline()
                            if tmpInput in ("", "j")
                                break
                            end
                            tempExpr = Meta.parse(tmpInput)
                            tmpShouldPay = eval(tempExpr) |> Float64
                            println(tempExpr, " = ", tmpShouldPay)
                            break
                        catch
                            println(colorstring("Invalid", :error), " number expression!")
                            print(colorstring(name, :member), " : ")
                        end
                    end
                    if tmpShouldPay == 0
                        tmpShouldPay = undef
                    end
                    tmpShouldPay != undef && push!(tmpBill.shouldPay, name => tmpShouldPay)
                end
                tmpSum = sum(values(tmpBill.shouldPay))
                if tmpBill.total != tmpSum
                    println("\nOops! Sum=", colorstring("$tmpSum", :error), " does not match Total=",
                        colorstring("$(tmpBill.total)", :warning), "\n")
                    tmpTip = tmpBill.total - tmpSum
                    if tmpTip < 0
                        continue
                    end
                    tmpTipPercents = 100 * round(tmpTip / tmpSum, digits = 3)
                    println("Is Total - Sum = ", colorstring("$tmpTip ($tmpTipPercents %)", :tip), " your tip?([y]/n)")
                    a = readline()
                    if a != "n"
                        tmpNumShouldPay = length(tmpBill.shouldPay)
                        println(colorstring("Tips", :tip), " for each member:")
                        accumTip = 0
                        countMemberTip = 0
                        for (m, v) in tmpBill.shouldPay
                            countMemberTip += 1
                            tmpMemberTip = tmpTip * v / tmpSum
                            if countMemberTip == tmpNumShouldPay
                                tmpMemberTip = tmpTip - accumTip
                            end
                            tmpBill.shouldPay[m] += tmpMemberTip
                            accumTip += tmpMemberTip
                            print_member_tip(m, tmpMemberTip)
                        end
                        if sum(values(tmpBill.shouldPay)) == tmpBill.total
                            bill = tmpBill
                            break
                        else
                            println("Rounding error exits!")
                        end
                    end
                else
                    bill = tmpBill
                    break
                end
            end
        else
            isAA = true
            bill.isAA = isAA

            println(colorstring("AA", :aa), " on all the members?([y]/n)")
            isAllAA = readline()
            AAlist = []
            if isAllAA == "n"
                while true
                    println("Check [y]/n ?")
                    for name in keys(payGrp.members)
                        print(colorstring(name, :member), " : ")
                        tmpIsAA = readline()
                        if tmpIsAA != "n"
                            push!(AAlist, name)
                        end
                    end
                    if !isempty(AAlist)
                        break
                    end
                    println(colorstring("Oops!", :error), " No one is ", colorstring("AA", :aa), "!")
                    println()
                end
            else
                AAlist = keys(payGrp.members)
            end
            avgPay = bill.total / length(AAlist)
            for name in AAlist
                push!(bill.shouldPay, name => avgPay)
            end
        end

        for (name, val) in bill.shouldPay
            tmpMemShouldPay = payGrp.members[name].shouldPay
            if haskey(tmpMemShouldPay, insertDate)
                push!(tmpMemShouldPay[insertDate], billname => val)
            else
                push!(tmpMemShouldPay, insertDate => Dict(billname => val))
            end
        end

        if haskey(payGrp.bills, insertDate)
            push!(payGrp.bills[insertDate], billname => bill)
        else
            push!(payGrp.bills, insertDate => Dict(billname => bill))
        end

        println()
        print_bill(bill)

        println()
        println("And do you have another bill?([y]/n)")
        hasNextBill = readline()
        if hasNextBill == "n"
            break
        else
            println()
            println("(", colorstring("Tip:", :tip), " Overwrite ", colorstring("any", :tip), " previous bill by inputting the same name.)\n")
            println("What's your next bill?")
        end
    end
    return payGrp
end
function add_bills!(g::PayGroup, d)
    try
        add_bills!(g, Date(d))
    catch
        print_invalid_date(d)
    end
end
add_bills!(g::PayGroup) = add_bills!(g, today())


"""
    gen_soln(payGrp::PayGroup) -> soln

Generate a payment solution from a `PayGroup`.
"""
function gen_soln(payGrp::PayGroup)
    payers = []
    receivers = []
    for (n, m) in payGrp.members
        tmpToPay = get_topay(m)
        if tmpToPay == 0
            continue
        elseif tmpToPay > 0
            push!(payers, (n, tmpToPay))
        else
            push!(receivers, (n, -tmpToPay))
        end
    end

    if isempty(payers)
        return [("Everyone", "happy", 0)]
    end

    payers = sort(payers; by = x -> x[2])
    receivers = sort(receivers; by = x -> x[2])
    if abs(sum(map(x -> x[2], payers)) - sum(map(x -> x[2], receivers))) > 0.01
        println("Source does NOT match sink!")
    end

    soln = []
    while !isempty(receivers)
        tmpPayer = payers[end]
        tmpReceiver = receivers[end]
        tmpDiff = tmpPayer[2] - tmpReceiver[2]
        if tmpDiff > 0.001
            push!(soln, (tmpPayer[1], tmpReceiver[1], tmpReceiver[2]))
            pop!(receivers)
            payers[end] = (tmpPayer[1], tmpDiff)
        elseif tmpDiff < -0.001
            push!(soln, (tmpPayer[1], tmpReceiver[1], tmpPayer[2]))
            pop!(payers)
            receivers[end] = (tmpReceiver[1], -tmpDiff)
        else
            push!(soln, (tmpPayer[1], tmpReceiver[1], tmpPayer[2]))
            pop!(payers)
            pop!(receivers)
        end
    end
    return soln
end
print_soln(g::PayGroup) = print_soln(gen_soln(g))

# ------------------------------------ IO ------------------------------------ #
# using JLD2: save_object, load_object
# save_paygrp(f::String, g::PayGroup) = save_object(f, g)
# save_paygrp(g::PayGroup) = save_paygrp("groupay.jld2", g)
# load_paygrp(f::String) = load_object(f)
# load_paygrp() = load_paygrp("groupay.jld2")
# export save_paygrp, load_paygrp

# ----------------------------- interactive usage ---------------------------- #
const MANUAL = (
    ("g", "show meta-info of your group"),
    ("gb", "show billnames"),
    ("s", "show payment solution"),
    ("b", "show all bills"),
    ("b foo", "show bills named by " * colorstring("foo", :bill)),
    ("m", "show all members' bills"),
    ("m bar", "show bills belonging to " * colorstring("bar", :member)),
    ("am", "add members"),
    ("ab", "add bills"),
    ("cb foo", "change bill " * colorstring("foo", :bill)),
    ("rb foo", "remove bill " * colorstring("foo", :bill)),
    ("hh", "help on $(colorstring("more", :warning)) commands"),
    # ("ab", "add bills \e[93mtoday\e[0m"),
    # ("ab 2008-8-8", "add bills on \e[93m2008-8-8\e[0m"),
    # ("sg", "save your group"),
    # ("lg", "load your group"),
    # ("dg", "delete your group")
)

const MOREMANUAL = (
    ("gm", "show members"),
    ("bd 2021-8-1", "show bills on " * colorstring("2021-8-1", :date)),
    ("m bar 2021-8-1", "show bills of member " * colorstring("bar", :member) * " on " * colorstring("2021-8-1", :date)),
    ("mt", "show today's bills for each member"),
    ("mt bar", "show today's bills of " * colorstring("bar", :member)),
    ("bt", "show today's bills"),
    ("bt foo", "show today's bill with name " * colorstring("foo", :bill)),
    ("ab 2021-8-1", "add bills on " * colorstring("2021-8-1", :date)),
    ("cb foo 2021-8-1", "change bill " * colorstring("foo", :bill) * " on " * colorstring("2021-8-1", :date)),
    ("rb foo 2021-8-1", "remove bill " * colorstring("foo", :bill) * " on " * colorstring("2021-8-1", :date)),
    ("cm foo bar", "change name of member " * colorstring("foo", :member) * " to " * colorstring("bar", :member)),
)

function print_man_element(cmd)
    println("  ", colorstring(cmd[1], :cmd), " : ", cmd[2])
end

function print_manual(man, t::String = "Command Manual")
    println(colorstring(t, :manual), ":")
    print_man_element.(man)
    println("Get help by ", colorstring("h", :green), "; quit by ", colorstring("q", :red), "\n")
end
print_manual() = print_manual(MANUAL)

print_invalid_cmd() = println(colorstring("Invalid", :error), " command!")

function exec_cmd(g::PayGroup, nextCmd)
    nextCmd = split(nextCmd)
    nextCmd = String.(nextCmd)
    if isempty(nextCmd)
        print_invalid_cmd()
        return false
    end

    headCmd = nextCmd[1]
    lenCmd = length(nextCmd)
    if headCmd == "q"
        return true
    elseif headCmd == "h"
        print_manual()
    elseif headCmd == "hh"
        print_manual(MOREMANUAL, "More Commands")
    elseif headCmd == "g"
        print_meta_info(g)
    elseif headCmd == "gm"
        print_meta_members(g)
    elseif headCmd == "gb"
        print_meta_bills(g)
    elseif headCmd == "s"
        print_soln(g)
    elseif headCmd == "b"
        if lenCmd >= 3
            print_bill(g, nextCmd[2], nextCmd[3])
        elseif lenCmd >= 2
            print_billbyname(g, nextCmd[2])
        else
            print_bill(g)
        end
    elseif headCmd == "bt"
        if lenCmd >= 2
            print_bill_today(g, nextCmd[2])
        else
            print_bill_today(g)
        end
    elseif headCmd == "bd"
        if lenCmd >= 2
            print_bill(g, nextCmd[2])
        else
            println("Please input the date to show bills.")
        end
    elseif headCmd == "m"
        if lenCmd >= 3
            print_member(g, nextCmd[2], nextCmd[3])
        elseif lenCmd >= 2
            print_member(g, nextCmd[2])
        else
            print_member(g)
        end
    elseif headCmd == "mt"
        if lenCmd >= 2
            print_member_today(g, nextCmd[2])
        else
            print_member_today(g)
        end
    elseif headCmd == "am"
        add_member!(g)
    elseif headCmd == "ab"
        if lenCmd >= 2
            add_bills!(g, nextCmd[2])
        else
            add_bills!(g)
        end
    elseif headCmd == "cb"
        if lenCmd >= 3
            ch_bill_cmd!(g, nextCmd[2], nextCmd[3])
        elseif lenCmd >= 2
            ch_bill!(g, nextCmd[2])
        else
            println("Please input a bill name to change.")
        end
    elseif headCmd == "rb"
        if lenCmd >= 3
            rm_bill_cmd!(g, nextCmd[2], nextCmd[3])
        elseif lenCmd >= 2
            rm_bill!(g, nextCmd[2])
        else
            println("Please input a bill name to remove.")
        end
    elseif headCmd == "cm"
        if lenCmd >= 3
            ch_member!(g, nextCmd[2], nextCmd[3])
        else
            println("Please input member to change name.")
        end
        # elseif headCmd == "sg"
        #     save_paygrp(g)
        #     println("Group saved!")
        # elseif headCmd == "lg"
        #     load_paygrp("groupay.jld2")
        # elseif headCmd == "dg"
        #     rm("groupay.jld2")
        #     println("\e[31mgroupap.jl\e[0m deleted!")
    else
        print_invalid_cmd()
    end
    return false
end

"""
execute commands recursively
"""
function cmd_flow(g::PayGroup)
    print_manual()
    shouldExit = false
    while !shouldExit
        println("What's next? ($(colorstring("h", :green)) to help; $(colorstring("q", :red)) to quit)")
        nextCmd = readline()
        println()
        shouldExit = exec_cmd(g, nextCmd)
        println()
    end
end

# TODO: reimplement the IO feature
function check_savedgroup()
    if isfile("groupay.jld2")
        println("A group saved at $(colorstring("groupay.jld2", :green)) has been detected!")
        println("Do you want to load it?([y]/n)")
        a = readline()
        if a == "n"
            println("Then let's start a new group.")
            return nothing, false
        else
            payGrp = load_paygrp("groupay.jld2")
            println()
            println("The saved group has been loaded! ^_^")
            print_meta_info(payGrp)
            println("Let's enter command mode directly :)")
            cmd_flow(payGrp)
            println("\nHave a good day ~")
            return payGrp, true
            # # enter cmd flow
            # println("\nDo you want to enter command mode directly?([y]/n)")
            # a = readline()
            # if a != "n"
            #     cmd_flow(payGrp)
            #     println("\nHave a good day ~")
            #     return payGrp
            # end
            # # interactive mode
            # println("Do you want to add more members?(y/[n])")
            # shouldAddMem = readline()
            # if shouldAddMem == "y"
            #     payGrp = add_member!(payGrp)
            # end
            # println()
            # println("And you have added the following bills:")
            # for (d, dateBills) in payGrp.bills
            #     println("< \e[93m", d, "\e[0m >")
            #     for billname in keys(dateBills)
            #         println("\e[33m", billname, "\e[0m")
            #     end
            # end
        end
    else
        return nothing, false
        # # generate group
        # println()
        # payGrp = gen_paygrp()
    end
end

function print_greetings()
    println("Hi, there! Welcome to happy ~ $(colorstring("group pay", :banner)) ~")
    println("We will provide you a payment solution for your group.")
end

function igroupay(shouldCheck = false)
    # greetings
    run(`clear`)
    print_greetings()
    # check saved group
    if shouldCheck
        println()
        payGrp, gstatus = check_savedgroup()
        if gstatus
            return payGrp
        end
    end
    # generate group
    println()
    payGrp = gen_paygrp()
    if shouldCheck
        println("And on today?([y]/n)")
        onToday = readline()
        if onToday == "n"
            while true
                println("So on which date? e.g., 2021-8-12")
                insertDate = readline()
                try
                    add_bills!(payGrp, insertDate)
                    break
                catch
                    println("Wrong date format!")
                end
            end
        else
            payGrp = add_bills!(payGrp)
        end
    else
        payGrp = add_bills!(payGrp)
    end

    # payment solution
    print_soln(payGrp)
    # save
    if shouldCheck
        println("\nDo you want to save your group?([y]/n)")
        a = readline()
        if a != "n"
            save_paygrp(payGrp)
            println("Group saved as $(colorstring("groupay.jld2", :path)) ^_^")
        end
    end
    # show info
    println("\nShow detailed information?([y]/n)")
    willContinue = readline()
    if willContinue == "n"
        println("\nHave a good day ~")
        return payGrp
    end
    # print bills
    println("\nShow all the bills?([y]/n)")
    a = readline()
    if a != "n"
        print_bill(payGrp)
    end
    # print bills of members
    println("And show all the bills based on members?([y]/n)")
    a = readline()
    if a != "n"
        print_member(payGrp)
    end
    # cmd flow
    println("\nDo you want to enter command mode?([y]/n)")
    a = readline()
    if a != "n"
        cmd_flow(payGrp)
        println("\nHave a good day ~")
        return payGrp
    end
    println("\nHave a good day ~")
    return payGrp
end

# -------------------------------- create app -------------------------------- #
function julia_main()::Cint
    try
        igroupay()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

end # module