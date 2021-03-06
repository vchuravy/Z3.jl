## Accessing Values from variables and models
## ==========================================

get_numeral_mk(::Type{Int64}) = get_numeral_int64
get_numeral_mk(::Type{Int32}) = get_numeral_int
get_numeral_mk(::Type{UInt64}) = get_numeral_uint64
get_numeral_mk(::Type{UInt32}) = get_numeral_uint

"""Get an abstract model which can be queried for Values
a = Var(Integer)
b = Var(Integer)
c = Var(Integer)
add!(a * b > c)
check()
m = model()
interpret(Rational, a, m)
"""
model(;ctx::Context=global_ctx(), solver::Solver=global_solver()) = solver_get_model(solver;ctx=ctx)

"Interpret a value `x` in a model `m`"
function interpret{T <: Integer}(
    ::Type{T},
    m::Model,
    x::RealVarAst;
    ctx::Context=global_ctx())
  qval = Ref{Ptr{Void}}(C_NULL)
  successful = Z3_model_eval(ctx.ptr, m.ptr, x.ptr, Int32(1), qval)
  if successful == 1
    qvalast = Ast(qval[])
    result_int = Ref{Int64}(0)
    result = get_numeral_mk(T)(ctx, qvalast, result_int)
    result_int[]::T
  else
    error("Failed to get model")
  end
end

"Interpret a value `x` in a model `m`"
function interpret(
    ::Type{Rational},
    m::Model,
    x::RealVarAst;
    ctx::Context=global_ctx())
  qval = Ref{Ptr{Void}}(C_NULL)
  successful = Z3_model_eval(ctx.ptr, m.ptr, x.ptr, Int32(1), qval)
  if successful == 1
    qvalast = Ast(qval[])
    result_num = Ref{Int64}(0)
    result_den = Ref{Int64}(0)
    result = get_numeral_rational_int64(ctx, qvalast, result_num, result_den)
    Rational(result_num[], result_den[])
  else
    error("Failed to get model")
  end
end

"Interpret a value `x` in a model `m`"
function interpret(
    ::Type{ASCIIString},
    m::Model,
    x::RealVarAst;
    ctx::Context=global_ctx())
  qval = Ref{Ptr{Void}}(C_NULL)
  successful = Z3_model_eval(ctx.ptr, m.ptr, x.ptr, Int32(1), qval)
  if successful == 1
    qvalast = Ast(qval[])
    result_num = Ref{Int64}(0)
    result_den = Ref{Int64}(0)
    result::ASCIIString = get_numeral_string(ctx, qvalast)
  else
    error("Failed to get model")
  end
end

# function model(
#     ::Type{BigFloat},
#     x::RealVarAst;
#     ctx::Context=global_ctx(),
#     solver::Solver=global_solver())
#
#   model_str = model(ASCIIString, x; solver=solver, ctx=ctx)
#   parse(BigFloat, model_str)
# end
#
# function model(
#     ::Type{BigInt},
#     x::RealVarAst;
#     ctx::Context=global_ctx(),
#     solver::Solver=global_solver())
#
#   model_str = model(ASCIIString, solver, x; ctx=ctx)
#   parse(BigInt, model_str)
# end


## Convenience
## ==========

"""Return a model of variable `x` in integer type `T`

A = Var(Integer)
add!(A > 100)
a_val = Var(Int64, A)
"""
function model{T}(
    ::Type{T},
    x::RealVarAst;
    ctx::Context=global_ctx(),
    solver::Solver=global_solver())

  m = solver_get_model(ctx, solver)
  model(T, x, m; ctx=ctx, solver=solver)
end

function interpret{T}(
    ::Type{T},
    m::Model,
    x::Tuple{Vararg{RealVarAst}};
    ctx::Context=global_ctx())
  map(xi->interpret(T, m, xi;ctx=ctx), x)
end

# Z3_model_get_const_interp (__in Z3_context c, __in Z3_model m, __in Z3_func_decl a)
##
# Z3_bool Z3_API 	Z3_get_numeral_small (__in Z3_context c, __in Z3_ast a, __out __int64 *num, __out __int64 *den)
#  	Return numeral value, as a pair of 64 bit numbers if the representation fits. More...
#
# Z3_ast Z3_API 	Z3_get_algebraic_number_lower (__in Z3_context c, __in Z3_ast a, __in unsigned precision)
#  	Return a lower bound for the given real algebraic number. The interval isolating the number is smaller than 1/10^precision. The result is a numeral AST of sort Real. More...
#
# Z3_ast Z3_API 	Z3_get_algebraic_number_upper (Z3_context c, Z3_ast a, unsigned precision)
#  	Return a upper bound for the given real algebraic number. The interval isolating the n
