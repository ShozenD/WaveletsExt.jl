# ========== Perform 1 step of discrete wavelet transform ==========
# ----- 1 step of dwt for 1D signals -----
"""
    dwt_step(v, h, g)

Perform one level of the discrete wavelet transform (DWT) on the vector `v`, which is the
`d`-th level scaling coefficients (Note the 0th level scaling coefficients is the raw
signal). The vectors `h` and `g` are the detail and scaling filters.

# Arguments
- `v::AbstractVector{T} where T<:Number`: Vector of coefficients from a node at level `d`.
- `h::Vector{S} where S<:Number`: High pass filter.
- `g::Vector{S} where S<:Number`: Low pass filter.

# Returns
- `w₁::Vector{T}`: Output from the low pass filter.
- `w₂::Vector{T}`: Output from the high pass filter.

# Examples
```julia
using Wavelets, WaveletsExt

# Setup
v = randn(8)
wt = wavelet(WT.haar)
g, h = WT.makereverseqmfpair(wt, true)

# One step of DWT
DWT.dwt_step(v, h, g)
```

**See also:** [`dwt_step!`](@ref), [`idwt_step`](@ref)
"""
function dwt_step(v::AbstractVector{T}, h::Array{S,1}, g::Array{S,1}) where 
                 {T<:Number, S<:Number}
    n = length(v)
    w₁ = zeros(T, n÷2)
    w₂ = zeros(T, n÷2)

    dwt_step!(w₁, w₂, v, h, g)
    return w₁, w₂
end

"""
    dwt_step!(w₂, w₂, v, h, g)

Same as `dwt_step` but without array allocation.

# Arguments
- `w₁::AbstractVector{T} where T<:Number`: Vector allocation for output from low pass
  filter.
- `w₂::AbstractVector{T} where T<:Number`: Vector allocation for output from high pass
  filter.
- `v::AbstractVector{T} where T<:Number`: Vector of coefficients from a node at level `d`.
- `h::Vector{S} where S<:Number`: High pass filter.
- `g::Vector{S} where S<:Number`: Low pass filter.

# Returns
- `w₁::Vector{T}`: Output from the low pass filter.
- `w₂::Vector{T}`: Output from the high pass filter.

# Examples
```julia
using Wavelets, WaveletsExt

# Setup
v = randn(8)
wt = wavelet(WT.haar)
g, h = WT.makereverseqmfpair(wt, true)
w₁ = zeros(8)
w₂ = zeros(8)

# One step of DWT
DWT.dwt_step!(w₁, w₂, v, 0, h, g)
```

**See also:** [`dwt_step`](@ref), [`idwt_step`](@ref)
"""
function dwt_step!(w₁::AbstractVector{T},
                   w₂::AbstractVector{T},
                   v::AbstractVector{T},
                   h::Array{S,1},
                   g::Array{S,1}) where {T<:Number, S<:Number}
    # Sanity check
    @assert length(w₁) == length(w₂) == length(v)÷2
    @assert length(h) == length(g)

    # Setup
    n = length(v)           # Parent length
    n₁ = length(w₁)         # Child length
    filtlen = length(h)     # Filter length

    # One step of discrete transform
    for i in 1:n₁
        k₁ = 2*i-1          # Start index for low pass filtering
        k₂ = 2*i            # Start index for high pass filtering
        @inbounds w₁[i] = g[end] * v[k₁]
        @inbounds w₂[i] = h[1] * v[k₂]
        for j in 2:filtlen
            k₁ = k₁+1 |> k₁ -> k₁>n ? mod1(k₁,n) : k₁
            k₂ = k₂-1 |> k₂ -> k₂≤0 ? mod1(k₂,n) : k₂
            @inbounds w₁[i] += g[end-j+1] * v[k₁]
            @inbounds w₂[i] += h[j] * v[k₂]
        end
    end
    return w₁, w₂
end

"""
    idwt_step(w₁, w₂, h, g)

Perform one level of the inverse discrete wavelet transform (IDWT) on the vectors `w₁` and
`w₂`, which are the scaling and detail coefficients. The vectors `h` and `g` are the detail
and scaling filters.

# Arguments
- `w₁::AbstractVector{T} where T<:Number`: Vector allocation for output from low pass
  filter.
- `w₂::AbstractVector{T} where T<:Number`: Vector allocation for output from high pass
  filter.
- `h::Vector{S} where S<:Number`: High pass filter.
- `g::Vector{S} where S<:Number`: Low pass filter.

# Returns
- `v::Vector{T}`: Reconstructed coefficients.

# Examples
```julia
using Wavelets, WaveletsExt

# Setup
v = randn(8)
wt = wavelet(WT.haar)
g, h = WT.makereverseqmfpair(wt, true)

# One step of SDWT
w₁, w₂ = DWT.dwt_step(v, h, g)

# One step of ISDWT
v̂ = DWT.idwt_step(w₁, w₂, h, g)
```

**See also:** [`idwt_step!`](@ref)
"""
function idwt_step(w₁::AbstractVector{T}, 
                   w₂::AbstractVector{T}, 
                   h::Array{S,1}, 
                   g::Array{S,1}) where {T<:Number, S<:Number}
    n = length(w₁)
    v = Vector{T}(undef, 2*n)
    idwt_step!(v, w₁, w₂, h, g)
    return v
end

"""
    idwt_step!(v, w₁, w₂, h, g)

Same as `idwt_step` but without array allocation.

# Arguments
- `v::AbstractVector{T} where T<:Number`: Vector allocation for reconstructed coefficients.
- `w₁::AbstractVector{T} where T<:Number`: Vector allocation for output from low pass
  filter.
- `w₂::AbstractVector{T} where T<:Number`: Vector allocation for output from high pass
  filter.
- `h::Vector{S} where S<:Number`: High pass filter.
- `g::Vector{S} where S<:Number`: Low pass filter.

# Returns
- `v::Vector{T}`: Reconstructed coefficients.


# Examples
```julia
using Wavelets, WaveletsExt

# Setup
v = randn(8)
v̂ = similar(v)
wt = wavelet(WT.haar)
g, h = WT.makereverseqmfpair(wt, true)

# One step of SDWT
w₁, w₂ = DWT.dwt_step(v, h, g)

# One step of ISDWT
DWT.idwt_step!(v̂, w₁, w₂, h, g)
```

**See also:** [`idwt_step`](@ref)
"""
function idwt_step!(v::AbstractVector{T},
                    w₁::AbstractVector{T},
                    w₂::AbstractVector{T},
                    h::Array{S,1},
                    g::Array{S,1}) where {T<:Number, S<:Number}
    # Sanity check
    @assert length(w₁) == length(w₂) == length(v)÷2
    @assert length(h) == length(g)

    # Setup
    n = length(v)           # Parent length
    n₁ = length(w₁)         # Child length
    filtlen = length(h)     # Filter length

    # One step of inverse discrete transform
    for i in 1:n
        j₀ = mod1(i,2)      # Pivot point to determine start index for filter
        j₁ = filtlen-j₀+1   # Index for low pass filter g
        j₂ = mod1(i+1,2)    # Index for high pass filter h
        k₁ = (i+1)>>1       # Index for approx coefs w₁
        k₂ = (i+1)>>1       # Index for detail coefs w₂
        @inbounds v[i] = g[j₁] * w₁[k₁] + h[j₂] * w₂[k₂]
        for j in (j₀+2):2:filtlen
            j₁ = filtlen-j+1
            j₂ = j + isodd(j) - iseven(j)
            k₁ = k₁-1 |> k₁ -> k₁≤0 ? mod1(k₁,n₁) : k₁
            k₂ = k₂+1 |> k₂ -> k₂>n₁ ? mod1(k₂,n₁) : k₂
            @inbounds v[i] += g[j₁] * w₁[k₁] + h[j₂] * w₂[k₂]
        end
    end
    return v
end

# ----- 1 step of dwt for 2D signals -----
"""
    dwt_step(v, h, g[; standard])

Compute 1 step of 2D discrete wavelet transform (DWT).

# Arguments
- `v::AbstractArray{T,2} where T<:Number`: Array of coefficients of size ``(n,m)``.
- `h::Array{S,1} where S<:Number`: High pass filter.
- `g::Array{S,1} where S<:Number`: Low pass filter.

# Keyword Arguments
- `standard::Bool`: (Default: `true`) Whether to perform the standard wavelet transform.

# Returns
- `w₁::Array{T,2}`: Top left output. Result of low pass filter on columns + low pass filter
  on rows.
- `w₂::Array{T,2}`: Top left output. Result of low pass filter on columns + high pass filter
  on rows.
- `w₃::Array{T,2}`: Top left output. Result of high pass filter on columns + low pass filter
  on rows.
- `w₄::Array{T,2}`: Top left output. Result of high pass filter on columns + high pass filter
  on rows.

# Examples
```julia
using Wavelets, WaveletsExt

# Setup
v = randn(8,8)
wt = wavelet(WT.haar)
g, h = WT.makereverseqmfpair(wt, true)

# One step of DWT
DWT.dwt_step(v, h, g)
```

**See also:** [`dwt_step`](@ref), [`dwt_step!`](@ref), [`idwt_step`](@ref)
"""
function dwt_step(v::AbstractArray{T,2}, h::Array{S,1}, g::Array{S,1}; 
                  standard::Bool = true) where {T<:Number, S<:Number}
    n,m = size(v)
    n₁ = n÷2
    m₁ = m÷2
    w₁ = Array{T,2}(undef, (n₁,m₁))
    w₂ = Array{T,2}(undef, (n₁,m₁))
    w₃ = Array{T,2}(undef, (n₁,m₁))
    w₄ = Array{T,2}(undef, (n₁,m₁))
    temp = Array{T,2}(undef, (n,m))
    dwt_step!(w₁, w₂, w₃, w₄, v, h, g, temp, standard=standard)
    return w₁, w₂, w₃, w₄
end

"""
    dwt_step!(v, w₁, w₂, w₃, w₄, h, g, temp[; standard])

Same as 2D version of `dwt_step` but without array allocation.

# Arguments
- `w₁::AbstractArray{T,2} where T<:Number`: Array allocation for top left output.
- `w₂::AbstractArray{T,2} where T<:Number`: Array allocation for top right output.
- `w₃::AbstractArray{T,2} where T<:Number`: Array allocation for bottom left output.
- `w₄::AbstractArray{T,2} where T<:Number`: Array allocation for bottom right output.
- `v::AbstractArray{T,2} where T<:Number`: Array of coefficients to be transformed.
- `h::Array{S,1} where S<:Number`: High pass filter.
- `g::Array{S,1} where S<:Number`: Low pass filter.
- `temp::AbstractArray{T,2} where T<:Number`: Array allocation for intermediate
  computations.

# Keyword Arguments
- `standard::Bool`: (Default: `true`) Whether to perform the standard wavelet transform.

# Returns
- `w₁::Array{T,2}`: Top left output. Result of low pass filter on columns + low pass filter
  on rows.
- `w₂::Array{T,2}`: Top left output. Result of low pass filter on columns + high pass filter
  on rows.
- `w₃::Array{T,2}`: Top left output. Result of high pass filter on columns + low pass filter
  on rows.
- `w₄::Array{T,2}`: Top left output. Result of high pass filter on columns + high pass filter
  on rows.

# Examples
```julia
using Wavelets, WaveletsExt

# Setup
v = randn(8,8)
temp = similar(v)
w₁ = Array{Float64,2}(undef, (4,4))
w₂ = Array{Float64,2}(undef, (4,4))
w₃ = Array{Float64,2}(undef, (4,4))
w₄ = Array{Float64,2}(undef, (4,4))
wt = wavelet(WT.haar)
g, h = WT.makereverseqmfpair(wt, true)

# One step of DWT
DWT.dwt_step!(w₁, w₂, w₃, w₄, v, h, g, temp)
```
"""
function dwt_step!(w₁::AbstractArray{T,2}, w₂::AbstractArray{T,2},
                   w₃::AbstractArray{T,2}, w₄::AbstractArray{T,2},
                   v::AbstractArray{T,2},
                   h::Array{S,1}, g::Array{S,1},
                   temp::AbstractArray{T,2};
                   standard::Bool = true) where {T<:Number, S<:Number}
    # Sanity check
    @assert size(v) == size(temp)
    @assert size(w₁) == size(w₂) == size(w₃) == size(w₄)
    @assert size(w₁,1)*2 == size(v,1)
    @assert size(w₁,2)*2 == size(v,2)

    # Setup
    n,m = size(w₁)

    # Transform
    if standard
        # Compute dwt for all columns
        for j in 1:(2*m)
            @inbounds temp₁ⱼ = @view temp[1:n,j]
            @inbounds temp₂ⱼ = @view temp[(n+1):end,j]
            @inbounds vⱼ = @view v[:,j]
            @inbounds dwt_step!(temp₁ⱼ, temp₂ⱼ, vⱼ, h, g)
        end
        # Compute dwt for all rows
        for i in 1:n
            @inbounds temp₁ᵢ = @view temp[i,:]
            @inbounds w₁ᵢ = @view w₁[i,:]
            @inbounds w₂ᵢ = @view w₂[i,:]
            @inbounds dwt_step!(w₁ᵢ, w₂ᵢ, temp₁ᵢ, h, g)
            
            @inbounds temp₂ᵢ = @view temp[n+i,:]
            @inbounds w₃ᵢ = @view w₃[i,:]
            @inbounds w₄ᵢ = @view w₄[i,:]
            @inbounds dwt_step!(w₃ᵢ, w₄ᵢ, temp₂ᵢ, h, g)
        end
    else
        error("Non-standard transform not implemented yet.")
    end
    return w₁, w₂, w₃, w₄
end

"""
    idwt_step(w₁, w₂, w₃, w₄, h, g; standard)

Computes one step of inverse discrete wavelet transform on 2D-signals.

# Arguments
- `w₁::AbstractArray{T,2} where T<:Number`: Top left child coefficients.
- `w₂::AbstractArray{T,2} where T<:Number`: Top right child coefficients.
- `w₃::AbstractArray{T,2} where T<:Number`: Bottom left child coefficients.
- `w₄::AbstractArray{T,2} where T<:Number`: Bottom right child coefficients.
- `h::Array{S,1} where S<:Number`: High pass filter.
- `g::Array{S,1} where S<:Number`: Low pass filter.

# Returns
- `::Array{T,2}`: Reconstructed coefficients.
"""
function idwt_step(w₁::AbstractArray{T,2}, w₂::AbstractArray{T,2},
                   w₃::AbstractArray{T,2}, w₄::AbstractArray{T,2},
                   h::Array{S,1}, g::Array{S,1};
                   standard::Bool = true) where {T<:Number, S<:Number}
    n,m = size(w₁)
    v = Array{T,2}(undef, (2*n,2*m))
    temp = Array{T,2}(undef, (2*n,2*m))
    idwt_step!(v, w₁, w₂, w₃, w₄, h, g, temp, standard=standard)
    return v
end

"""
    idwt_step!(v, w₁, w₂, w₃, w₄, h, g, temp[; standard])

Same as 2D version of `idwt_step` but without array allocation.

# Arguments
- `v::AbstractArray{T,2} where T<:Number`: Array allocation for inverse transformed output.
- `w₁::AbstractArray{T,2} where T<:Number`: Array allocation for top left coefficients.
- `w₂::AbstractArray{T,2} where T<:Number`: Array allocation for top right coefficients.
- `w₃::AbstractArray{T,2} where T<:Number`: Array allocation for bottom left coefficients.
- `w₄::AbstractArray{T,2} where T<:Number`: Array allocation for bottom right coefficients.
- `h::Array{S,1} where S<:Number`: High pass filter.
- `g::Array{S,1} where S<:Number`: Low pass filter.
- `temp::AbstractArray{T,2} where T<:Number`: Array allocation for intermediate
  computations.

# Keyword Arguments
- `standard::Bool`: (Default: `true`) Whether to perform the standard wavelet transform.

# Returns
- `v::Array{T,2}`: Reconstructed coefficients.
"""
function idwt_step!(v::AbstractArray{T,2},
                    w₁::AbstractArray{T,2}, w₂::AbstractArray{T,2},
                    w₃::AbstractArray{T,2}, w₄::AbstractArray{T,2},
                    h::Array{S,1}, g::Array{S,1},
                    temp::AbstractArray{T,2};
                    standard::Bool = true) where {T<:Number, S<:Number}
    # Sanity check
    @assert size(v) == size(temp)
    @assert size(w₁) == size(w₂) == size(w₃) == size(w₄)
    @assert size(w₁,1)*2 == size(v,1)
    @assert size(w₁,2)*2 == size(v,2)

    # Setup
    n,m = size(w₁)

    # Inverse transform
    if standard
        # Compute idwt for all rows
        for i in 1:n
            @inbounds temp₁ᵢ = @view temp[i,:]
            @inbounds w₁ᵢ = @view w₁[i,:]
            @inbounds w₂ᵢ = @view w₂[i,:]
            @inbounds idwt_step!(temp₁ᵢ, w₁ᵢ, w₂ᵢ, h, g)

            @inbounds temp₂ᵢ = @view temp[n+i,:]
            @inbounds w₃ᵢ = @view w₃[i,:]
            @inbounds w₄ᵢ = @view w₄[i,:]
            @inbounds idwt_step!(temp₂ᵢ, w₃ᵢ, w₄ᵢ, h, g)
        end
        # Compute idwt for all columns
        for j in 1:(2*m)
            @inbounds vⱼ = @view v[:,j]
            @inbounds temp₁ⱼ = @view temp[1:n,j]
            @inbounds temp₂ⱼ = @view temp[(n+1):end,j]
            @inbounds idwt_step!(vⱼ, temp₁ⱼ, temp₂ⱼ, h, g)
        end
    else
        error("Non-standard transform not implemented yet.")
    end
    return v
end

# ----- 1 step of dwt for nD signals -----
# TODO: Implement this function