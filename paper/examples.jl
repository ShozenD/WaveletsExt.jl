# ===== Showcasing the main functionalities of WaveletsExt.jl =====

using Plots,
      Wavelets,
      WaveletsExt

# 1. Additional Redundant Wavelet Transform Methods ----------------------------------------
#    On top of maximal overlap transform implemented in Wavelets.jl, WaveletsExt.jl has
#    additional redundant transform functions through Autocorrelation Wavelet Transforms
#    (Beylkin, Saito), Stationary Wavelet Transforms (Nason, Silverman), and Shift Invariant
#    Wavelet Transforms (Cohen, Raz, Malah).

x = zeros(1<<8)
x[128] = 1
wt = wavelet(WT.db4)                    # Construct Daubechies 4-tap wavelet filter

# ----- Autocorrelation Wavelet Transforms -----
y = acdwt(x, wt)
p1 = wiggle(y) |> p -> plot!(p, yticks=1:9, title="Autocorrelation WT")

# ----- Stationary Wavelet Transforms -----
y = sdwt(x, wt)
p2 = wiggle(y) |> p -> plot!(p, yticks=1:9, title="Stationary WT")

# Combine and save plot
p = plot(p1, p2, layout=(1,2))
savefig(p, "transforms.png")

# 2. Best Basis Algorithms -----------------------------------------------------------------
#    Compared to Wavelets.jl, WaveletsExt.jl has an extended ability of catering toward
#    multiple signals at once via Joint Best Basis (JBB) and Least Statistically Dependent
#    Basis (LSDB). One may then use the `plot_tfbdry` function implemented in WaveletsExt.jl
#    to analyze the best basis subspace.

# Generate 100 noisy heavisine signals of length 2⁸
x = generatesignals(:heavisine, 8) |> x -> duplicatesignals(x, 100, 2, true, 0.5)
# Wavelet packet decomposition of all signals
xw = wpdall(x, wt, 6)

# ----- Joint Best Basis (JBB)
tree = bestbasistree(xw, JBB())
p1 = plot_tfbdry(tree, 6, nd_col=:green, ln_col=:black, bg_col=:white) |> 
     p -> plot!(p, title="JBB")

# ----- Least Statistically Dependent Basis (LSDB)
tree = bestbasistree(xw, LSDB())
p2 = plot_tfbdry(tree, 6, nd_col=:green, ln_col=:black, bg_col=:white) |> 
     p -> plot!(p, title="LSDB")

# Combine and save plot
p = plot(p1, p2, layout=(1,2))
savefig(p, "paper/bestbasis.png")

# 3. Denoising Algorithms ------------------------------------------------------------------
#    There are two functions available: `denoise` and `denoiseall`. The former denoises one
#    signal whereas the latter denoises multiple signals at once.

# Generate 6 circularly shifted original heavisine signals
x₀ = generatesignals(:heavisine, 8) |> x -> duplicatesignals(x, 6, 2, false)
# Generate 6 noisy versions of the original signals
x = generatesignals(:heavisine, 8) |> x -> duplicatesignals(x, 6, 2, true, 0.8)

# Decompose each noisy signal
xw = wpdall(x, wt)

# Get best basis tree from the decomposition of signals
bt = bestbasistree(xw, JBB())
# Get best basis coefficients based on best basis tree
y = getbasiscoefall(xw, bt)

# Denoise all signals based on computed best basis tree
x̂ = denoiseall(y, :wpt, wt, tree=bt)

# Plot results
xs = repeat([0,256],6) |> x -> reshape(x, (2,6))
ys = repeat(1:6, inner=2) |> x -> reshape(x, (2,6))
p1 = plot(title="Noisy Signals")
wiggle!(x₀, sc=0.7, FaceColor=:white, ZDir=:reverse)
wiggle!(x, sc=0.7, EdgeColor=:red, FaceColor=:white, ZDir=:reverse)
plot!(p1, xs, ys, lc=:black)

p2 = plot(title="Denoised Signals")
wiggle!(x₀, sc=0.7, FaceColor=:white, ZDir=:reverse)
wiggle!(x̂, sc=0.7, EdgeColor=:blue, FaceColor=:white, ZDir=:reverse)
plot!(p2, xs, ys, lc=:black)

# Combine and save plot
p = plot(p1, p2, layout=(1,2))
savefig(p, "paper/denoising.png")

# 4. Feature Extraction Algorithm For Signals ----------------------------------------------
#    The feature extraction algorithm implemented in WaveletsExt.jl is the Local
#    Discriminant Basis (LDB) (Saito, Coifman).

# Generate 100 signals for each class of cylinder-bell-funnel
X, y = generateclassdata(ClassData(:cbf, 100, 100, 100))
# View sample signals and how each class differs from one another
cylinder = wiggle(X[:,1:5], sc=0.3)
plot!(cylinder, yticks=1:5, title="Cylinder signals")
bell = wiggle(X[:,101:105], sc=0.3)
plot!(bell, yticks=1:5, title="Bell signals")
funnel = wiggle(X[:,201:205], sc=0.3)
plot!(funnel, yticks=1:5, title="Funnel signals")
p1 = plot(cylinder, bell, funnel, layout=(3,1))

# Define Local Discriminant Basis object (`n_features` can be tweaked depending on the
# number of desired features to be used as input into classification model)
wt = wavelet(WT.coif4)
ldb = LocalDiscriminantBasis(wt=wt,
                             max_dec_level=6,
                             dm=SymmetricRelativeEntropy(),
                             en=TimeFrequency(),
                             dp=BasisDiscriminantMeasure(),
                             top_k=10,
                             n_features=10)
                            
# Fit and transform signals into features using LDB
X̂ = fit_transform(ldb, X, y)

# Plot the best basis for feature extraction
p2 = plot_tfbdry(ldb.tree, 6, nd_col=:green, ln_col=:black, bg_col=:white)
plot!(p2, title="Basis Selection using LDB")

p = plot(p1, p2, size=(600,300))
savefig(p, "paper/ldb.png")