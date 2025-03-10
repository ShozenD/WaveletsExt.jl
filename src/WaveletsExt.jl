__precompile__()

module WaveletsExt

include("mod/Utils.jl")
include("mod/DWT.jl")
include("mod/TIWT.jl")
include("mod/SIWPD.jl")
include("mod/ACWT.jl")
include("mod/BestBasis.jl")
include("mod/SWT.jl")
include("mod/Denoising.jl")
include("mod/LDB.jl")
include("mod/Visualizations.jl")

using Reexport
@reexport using .DWT,
                .BestBasis,
                .Denoising,
                .Utils,
                .LDB,
                .TIWT,
                .SWT,
                .SIWPD,
                .ACWT,
                .Visualizations

end