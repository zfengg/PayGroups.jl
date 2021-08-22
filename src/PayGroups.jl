module PayGroups

using Dates

export Member, PayGroup
export igroupay, gen_paygrp, add_bills!, add_member!
export print_member, print_bill, print_soln, print_metainfo

# ---------------------------------------------------------------------------- #
"""
    `Member` struct in the group
"""
mutable struct Member
    name::String
    shouldPay::Dict
    hasPaid::Dict
    Member(name::String) = new(name, Dict(), Dict())
end
get_toPay(m::Member) = sum(values(m.shouldPay)) - sum(values(m.hasPaid))

"""
    PayGroup

The object contains all the information about group payment.
"""
mutable struct PayGroup
    title::String
    date::Date
    members::Dict
    billMetaInfo::Dict
    billDetails::Dict
    PayGroup(title::String, date::Date) = new(title, date, Dict(), Dict(), Dict())
    PayGroup(title::String) = PayGroup(title, Dates.today())
end

"""
    print_member(m::Member)

    Print payment information of `m`.
"""
function print_member(m::Member)
    println("[\e[36m", m.name, "\e[0m]")
    if isempty(m.hasPaid)
        println("\e[35m No record yet.\e[0m\n")
        return nothing
    end
    println("-- has paid")
    for (k, v) in m.hasPaid
        println("\e[33m", k, "\e[0m : ", v)
    end
    println("total = \e[32m", sum(values(m.hasPaid)), "\e[0m")
    println("-- should pay")
    for (k, v) in m.shouldPay
        println("\e[33m", k, "\e[0m : ", v)
    end
    println("total = \e[31m", sum(values(m.shouldPay)), "\e[0m")
    println("-- remains to pay: \e[35m", get_toPay(m), "\e[0m\n")
end
function print_member(g::PayGroup, mn::String)
    if haskey(g.members, mn)
        print_member(g.members[mn])
    else
        println("Oops, \e[36m", mn, "\e[0m is not in your group!")
    end
end

"""
    print_member(x::PayGroup)

payment information for all the members in `x::PayGroup`.
"""
function print_member(g::PayGroup)
    println("\n======\n")
    for m in values(g.members)
        print_member(m)
    end
    println("======\n")
end

"""
    gen_paygrp() -> payGrp::PayGroup

Generate a `PayGroup` interactively.
"""
function gen_paygrp()
    println("What's the name of your group?")
    title = readline()
    while isempty(title)
        println("Why not name your group? ^o^")
        println("Please give it a nice name:")
        title = readline()
    end
    payGrp = PayGroup(title)
    println("And who are in the group \e[31m", title, "\e[0m?")
    members = String[]
    while true
        membersTmp = readline()
        append!(members, split(membersTmp))
        println()
        println("Your group now contains \e[31m", length(members), "\e[0m members:")
        for x in members
            println("\e[36m", x, "\e[0m")
        end
        println()
        println("Do you want to add more members?(y/[n])")
        flagInputName = readline()
        if flagInputName == "y"
            println()
            println("Please add the names of the others:")
        elseif length(members) == 0
            println()
            println("haha~ such a joke that a group with \e[31mNO\e[0m members!")
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

"""
    add_member!(x::PayGroup) -> x::PayGroup

Add more members to a `PayGroup` interactively.
"""
function add_member!(payGrp::PayGroup)
    println("Let's add more members!")
    println("Current members in \e[31m", payGrp.title, "\e[0m:")
    for x in keys(payGrp.members)
        println("\e[36m", x, "\e[0m")
    end

    println("\n(\e[31mWarning\e[0m: Repeated names may crash the whole process ^_^!)\n")
    println("Who else do you want to add?")
    addMembers = String[]
    while true
        membersTmp = readline()
        append!(addMembers, split(membersTmp))

        println()
        println("The following \e[31m", length(addMembers), "\e[0m members are added:")
        for x in addMembers
            println("\e[36m", x, "\e[0m")
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
        push!(payGrp.members, name => Member(name))
    end

    println("\nUpdated members in \e[31m", payGrp.title, "\e[0m:")
    for x in keys(payGrp.members)
        println("\e[36m", x, "\e[0m")
    end

    return payGrp
end

"""
Generate 'billDetails' from a `::Dict`.
"""
function get_bill_details(m::Dict, bn::String)
    billDetails = Dict()
    for (name, member) in m
        if haskey(member.shouldPay, bn)
            push!(billDetails, member.name => member.shouldPay[bn])
        end
    end
    return billDetails
end
get_bill_details(g::PayGroup, bn::String) = get_bill_details(g.members, bn)

"""
    print_bill(billname::String, x::PayGroup)

Print the information of bills.
"""
function print_bill(g::PayGroup, bn::String)
    if ! haskey(g.billMetaInfo, bn)
        println("Oops, \e[33m", bn, "\e[0m is not your bill!")
        return nothing
    end

    println("[\e[33m", bn, "\e[0m]")
    payTotal = g.billMetaInfo[bn][1]
    payMan = g.billMetaInfo[bn][2]
    println("total = \e[31m", payTotal, "\e[0m paid by \e[36m", payMan, "\e[0m;")
    if g.billMetaInfo[bn][3]
        println("-- \e[34mAA\e[0m --")
    else
        println("-- \e[34mnot AA\e[0m --")
    end
    for (key, val) in g.billDetails[bn]
        println("\e[36m", key, "\e[0m => ", val)
    end
    println()
end

function print_metainfo(g::PayGroup)
    println("Group: \e[91m", g.title, "\e[0m")
    println("Date: \e[95m", g.date, "\e[0m")
    print("Members: \e[36m")
    for name in keys(g.members)
        print(name, " ")
    end
    print("\e[0m\n")
    println("Total: \e[92m", sum(i[1] for i in values(g.billMetaInfo)), "\e[0m")
    println()
end
"""
    print_bill(x::PayGroup)

Print the information of all the bills in `x::PayGroup`.
"""
function print_bill(g::PayGroup)
    println("\n======\n")
    print_metainfo(g)
    for bn in keys(g.billDetails)
        print_bill(g, bn)
    end
    println("======\n")
end

"""
    add_bills!(payGrp::PayGroup) -> payGrp::PayGroup

Add bills to a `PayGroup`.
"""
function add_bills!(payGrp::PayGroup)
    println()

    if length(payGrp.members) == 1
        println("Ok, nice to meet you!")
        payMan = undef
        for x in keys(payGrp.members)
            println("\e[36m", x, "\e[0m")
            payMan = x
        end
        if ! isempty(payGrp.billMetaInfo)
            println("And you have added the following bills:")
            for billname in keys(payGrp.billMetaInfo)
                println("\e[33m", billname, "\e[0m")
            end
            println("\n(\e[32mTip:\e[0m Overwrite \e[32many\e[0m previous bill by inputting the same name.)\n")
            println("What's your next bill to add?")
        else
            println("Then let's review your bills together.")
            println()
            println("What's your first bill to add?")
        end

        while true
            # meta info
            billname = readline()
            while isempty(billname)
                println("It's better to give the bill a name, right? ^o^")
                println("So please name your bill:")
                billname = readline()
            end

            println("And how much have you paid for \e[33m", billname, "\e[0m?")
            payTotal = undef
            while true
                try
                    tempExpr = Meta.parse(readline())
                    payTotal = eval(tempExpr) |> Float64
                    println(tempExpr, " = ", payTotal)
                    break
                catch
                    print("Oops, \e[31minvalid\e[0m money input! ")
                    print("Please input a \e[32mnumber\e[0m or \e[32mmath-expression\e[0m:\n")
                end
            end
            for (name, member) in payGrp.members
                if name == payMan
                    push!(member.hasPaid, billname => payTotal)
                else
                    push!(member.hasPaid, billname => 0.)
                end
            end

            isAA = true
            push!(payGrp.members[payMan].shouldPay, billname => payTotal)
            push!(payGrp.billMetaInfo, billname => (payTotal, payMan, isAA))
            billDetails = Dict(payMan => payTotal)
            push!(payGrp.billDetails, billname => billDetails)
            println()
            print_bill(payGrp, billname)

            println()
            println("And do you have another bill?([y]/n)")
            hasNextBill = readline()
            if hasNextBill == "n"
                break
            else
                println("\n(\e[32mTip:\e[0m Overwrite \e[32many\e[0m previous bill by inputting the same name.)\n")
                println("What's your next bill?")
            end
        end
        return payGrp
    end

    println("Ok, nice to meet you all!")
    for x in keys(payGrp.members)
        println("\e[36m", x, "\e[0m")
    end
    if ! isempty(payGrp.billMetaInfo)
        println("And you have added the following bills:")
        for billname in keys(payGrp.billMetaInfo)
            println("\e[33m", billname, "\e[0m")
        end
        println("\n(\e[32mTip:\e[0m Overwrite \e[32many\e[0m previous bill by inputting the same name.)\n")
        println("What's your next bill to add?")
    else
        println("Then let's review your bills together.")
        println()
        println("What's your first bill to add?")
    end

    while true
        # meta info
        billname = readline()
        while isempty(billname)
            println("It's better to give the bill a name, right? ^o^")
            println("So please name your bill:")
            billname = readline()
        end
        println("Who pays \e[33m", billname, "\e[0m?")
        payMan = undef
        while true
            payMan = readline()
            if payMan in keys(payGrp.members)
                break
            else
                println("Oops, \e[36m", payMan, "\e[0m is not in your group! Please input the name again:")
            end
        end
        println("And how much has \e[36m", payMan, "\e[0m paid?")
        payTotal = undef
        while true
            try
                tempExpr = Meta.parse(readline())
                payTotal = eval(tempExpr) |> Float64
                println(tempExpr, " = ", payTotal)
                break
            catch
                print("Oops, \e[31minvalid\e[0m money input! ")
                print("Please input a \e[32mnumber\e[0m or \e[32mmath-expression\e[0m:\n")
            end
        end
        for (name, member) in payGrp.members
            if name == payMan
                push!(member.hasPaid, billname => payTotal)
            else
                push!(member.hasPaid, billname => 0.)
            end
        end

        # details
        println("Do you \e[34mAA\e[0m?([y]/n)")
        isAA = readline()
        if isAA == "n"
            isAA = false
            billDetails = undef
            while true
                tmpMembers = copy(payGrp.members)
                println("How much should each member pay?")
                for (name, member) in tmpMembers
                    print("\e[36m", name, "\e[0m : ")
                    tmpShouldPay = undef
                    while true
                        try
                            tempExpr = Meta.parse(readline())
                            tmpShouldPay = eval(tempExpr) |> Float64
                            println(tempExpr, " = ", tmpShouldPay)
                            break
                        catch
                            println("\e[31mInvalid\e[0m number expression!")
                            print("\e[36m", name, "\e[0m : ")
                        end
                    end
                    push!(member.shouldPay, billname => tmpShouldPay)
                end

                billDetails = get_bill_details(tmpMembers, billname)
                if payTotal != sum(values(billDetails))
                    println()
                    println("Oops! The sum of money doesn't match the total \e[32m", payTotal, "\e[0m!")
                    println("Please input again.")
                    println()
                else
                    payGrp.members = tmpMembers
                    break
                end
            end
        else
            isAA = true
            println("\e[34mAA\e[0m on all the members?([y]/n)")
            isAllAA = readline()
            AAlist = []
            if isAllAA == "n"
                println("Check [y]/n ?")
                for name in keys(payGrp.members)
                    print("\e[36m", name, "\e[0m : ")
                    tmpIsAA = readline()
                    if tmpIsAA != "n"
                        push!(AAlist, name)
                    end
                end
            else
                AAlist = keys(payGrp.members)
            end
            avgPay = payTotal / length(AAlist)
            for name in keys(payGrp.members)
                if name in AAlist
                    push!(payGrp.members[name].shouldPay, billname => avgPay)
                else
                    push!(payGrp.members[name].shouldPay, billname => 0.)
                end
            end
        end

        push!(payGrp.billMetaInfo, billname => (payTotal, payMan, isAA))
        billDetails = get_bill_details(payGrp, billname)
        push!(payGrp.billDetails, billname => billDetails)
        println()
        print_bill(payGrp, billname)

        println()
        println("And do you have another bill?([y]/n)")
        hasNextBill = readline()
        if hasNextBill == "n"
            break
        else
            println("\n(\e[32mTip:\e[0m Overwrite \e[32many\e[0m previous bill by inputting the same name.)\n")
            println("What's your next bill?")
        end
    end
    return payGrp
end

"""
    gen_soln(payGrp::PayGroup) -> soln

    Generate a payment solution from a `PayGroup`.
"""
function gen_soln(payGrp::PayGroup)
    payers = []
    receivers = []
    for (name, member) in payGrp.members
        if isempty(member.hasPaid)
            continue
        end

        tmpToPay = get_toPay(member)
        if tmpToPay == 0
            continue
        elseif tmpToPay > 0
            push!(payers, (name, tmpToPay))
        else
            push!(receivers, (name, -tmpToPay))
        end
    end

    if isempty(payers)
        return [("Everyone", "happy", 0)]
    end

    payers = sort(payers; by=x -> x[2])
    receivers = sort(receivers; by=x -> x[2])
    if abs(sum(map(x -> x[2], payers)) - sum(map(x -> x[2], receivers))) > 0.01
        println("Source does NOT match sink!")
    end

    soln = []
    while ! isempty(receivers)
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
            receivers[end] = (tmpReceiver[1], - tmpDiff)
        else
            push!(soln, (tmpPayer[1], tmpReceiver[1], tmpPayer[2]))
            pop!(payers)
            pop!(receivers)
        end
    end
    return soln
end

"""
    Print the payment solution.
"""
function print_soln(soln)
    println("\nTada! Here is a \e[32mpayment solution\e[0m :)\n")
    if soln[1][3] == 0
        println("\e[36m Congrats! Everyone is happy. \e[0m")
    else
        for tuple in soln
            println("\e[36m", tuple[1], "\e[0m => \e[36m", tuple[2], "\e[0m : ", tuple[3])
        end
    end
    println()
end
print_soln(x::PayGroup) = print_soln(gen_soln(x))


"""
    Interactively manage struct `PayGroup`.
"""
function igroupay()
    run(`clear`)
    println("Hi, there! Welcome to happy ~\e[32m group pay \e[0m~")
    println("We will provide you a payment solution for your group.")
    println()
    # input_members
    payGrp = gen_paygrp()
    # input_bills
    payGrp = add_bills!(payGrp)
    # payment solution
    print_soln(payGrp)
    println()
    println("Show detailed information?([y]/n)")
    willContinue = readline()
    if willContinue == "n"
        println()
        println("Have a good day ~")
        return payGrp
    end
    # print bills
    println()
    println("Show all the bills?([y]/n)")
    ynFlag = readline()
    if ynFlag == "n"
    else
        print_bill(payGrp)
    end
    # print bills of members
    println("And show all the bills based on members?([y]/n)")
    ynFlag = readline()
    if ynFlag == "n"
    else
        print_member(payGrp)
    end
    # manual
    manual = (
        ("g", "show meta-info of your group"),
        ("s", "show payment solution"),
        ("b", "show all bills"),
        ("b foo", "show bill with name \e[33mfoo\e[0m"),
        ("m", "show bills of all members"),
        ("m bar", "show bills of member \e[36mbar\e[0m"),
        ("am", "add members to your group"),
        ("ab", "add bills to your group"),
    )

    function print_man_element(cmd)
        println("  \e[32m", cmd[1], "\e[0m : ", cmd[2])
    end

    function print_manual(man)
        println("\e[35mCommand manual\e[0m:")
        print_man_element.(man)
        println("Get help by \e[32mh\e[0m; quit by \e[31mq\e[0m\n")
    end
    print_manual() = print_manual(manual)

    print_invalidcmd() = println("\e[31mInvalid\e[0m command! Please input again.")
    function exec_cmd(g::PayGroup, nextCmd)
        nextCmd = split(nextCmd)
        nextCmd = String.(nextCmd)
        if isempty(nextCmd)
            print_invalidcmd()
            return false
        end

        headCmd = nextCmd[1]
        lenCmd = length(nextCmd)
        if headCmd == "q"
            return true
        elseif headCmd == "h"
            print_manual()
        elseif headCmd == "g"
            print_metainfo(g)
        elseif headCmd == "s"
            print_soln(g)
        elseif headCmd == "b"
            if lenCmd >= 2
                print_bill(g, nextCmd[2])
            else
                print_bill(g)
            end
        elseif headCmd == "m"
            if lenCmd >= 2
                print_member(g, nextCmd[2])
            else
                print_member(g)
            end
        elseif headCmd == "am"
            add_member!(g)
        elseif headCmd == "ab"
            add_bills!(g)
        else
            print_invalidcmd()
        end
        return false
    end

    """
    execute commands recursively
    """
    function cmd_flow(g::PayGroup)
        println()
        print_manual()
        shouldExit = false
        while ! shouldExit
            println("What's next? (\e[32mh\e[0m to help; \e[31mq\e[0m to quit)")
            nextCmd = readline()
            println()
            shouldExit = exec_cmd(g, nextCmd)
            println()
        end
    end

    # enter cmd mode
    println("\nDo you want to enter command mode?([y]/n)")
    willContinue = readline()
    if willContinue == "n"
        println()
        println("Have a good day ~")
        return payGrp
    end
    cmd_flow(payGrp)
    println()
    println("Have a good day ~")
    return payGrp
end

end # module