#curdir = pwd()
#println("we are in $curdir")
#res = find_library(["libmsieve"],[curdir])
#println("lib loc is '$res'")

res = find_library(["libsmsieve"])
dlopen(res)

const libname =  "/home/jlapeyre/software_source/factoring/msieve/mymsieve2/msieve-1.52/libsmsieve.so"

# Send the string to msieve and return c struct msieve_obj
# Actually only single threaded.
runmsieve(n::String) = ccall((:factor_from_string,libname), Ptr{Void}, (Ptr{Uint8},Int), n, CPU_CORES)
# Send ptr to msieve_obj and get ptr to struct factors
getfactors(obj) = ccall((:get_factors_from_obj,libname), Ptr{Void}, (Ptr{Void},), obj)
# Sent ptr to struct factors and get number of factors
get_num_factors(factors) = ccall((:get_num_factors,libname), Int, (Ptr{Void},), factors)
msieve_free(obj) =  ccall((:msieve_obj_free_2,libname), Void, (Ptr{Void},), obj)

# Send ptr to struct factor and get string rep of one factor
# ptr to next struct factor, correponding to next factor, is returned.
function get_one_factor_value(factor)
    a = Array(Uint8,500) # max num digits input to msieve is 300
    nextfactor = ccall((:get_one_factor_value,libname), Ptr{Void}, (Ptr{Void},Ptr{Uint8},Int),
                       factor,a,length(a))
    return(nextfactor,bytestring(convert(Ptr{Uint8},a)))
end

# Send ptr to first struct factor. Return all factors as array of strings 
function get_all_factor_values(factor)
    allf = Array(String,0)
    nfactor = factor
    n = get_num_factors(factor)
    for i in 1:n
        (nfactor,sfact) = get_one_factor_value(nfactor)
        push!(allf,sfact)
    end
    return allf
end

# Send n as string to msieve, return all factors as array of strings
function runallmsieve(n::String)
    obj = runmsieve(n)
    thefactors = getfactors(obj)
    sfactors = get_all_factor_values(thefactors)
    msieve_free(obj)
    sfactors
end

# input factors as Array of strings. Output Array of Integers (Usually of type Int)
function factor_strings_to_integers(sfactors::Array{String})
    m = length(sfactors)
    n1 = eval(parse(sfactors[m]))
    T = typeof(n1)
    arr = Array(T,m)
    arr[m] = n1
    for i in 1:m-1
        arr[i] = parseint(T,sfactors[i])
    end
    arr    
end

# Send string to msieve. Return factors as list of Integers.
mfactorl(n::String) = factor_strings_to_integers(runallmsieve(n))

# Send string to msieve. Return factors in Dict, like Base.factor
function mfactor(n::String)
    arr = mfactorl(n)
    T = eltype(arr)
    d = (T=>Int)[]
    for i in arr d[i] = get(d,i,0) + 1 end
    d
end

# Input Integer. Use msieve and return factors in Dict, like Base.factor
function mfactor(n::Integer)
    n > 0 || error("number to be factored must be positive")
    mfactor(string(n))
end

