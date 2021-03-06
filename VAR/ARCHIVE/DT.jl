include("VARfuncs.jl")
using IterableTables, DataFrames, ExcelReaders, PyPlot #, HypothesisTests

dat = readxlsheet(DataFrame, "DataVAR.xlsx", "Sheet1", header=true)
datVAR = dat[:,2:end]
TT  = length(dat[1])
P   = 2
N   = size(datVAR)[2]



##plotts(Y, "data", ["GDP", "M3", "FF"])
dat_lags = lagmatrix(datVAR,2)
Z   = dat_lags[:,N+1:end].'
Zc  = [Z; ones(1,TT-P)]
z   = vec(dat_lags[:,1:N])
X   = kron(eye(N),Z')
Xc  = kron(eye(N),Zc')
Xt  = [X repmat(1:TT-P, N)]
Xct = [Xc repmat(1:TT-P, N)] 

βt  = (Xt.'*Xt)\Xt.' *z
αt  = βt[end]
βt  = reshape(βt[1:end-1], 5,2,5)
βt  = permutedims(permutedims(βt, [1,3,2]), [2,1,3])


β  = (X.'*X)\X.' *z
β  = reshape(β, 5,2,5)
β  = permutedims(permutedims(β, [1,3,2]), [2,1,3])

βc  = (Xc.'*Xc)\Xc.'*z
ind_cons = N*P*collect(1:N) + collect(1:N)
ind_nocons = setdiff(collect(1:N*N*P+N), ind_cons)
μc  = βc[ind_cons]
βc  = reshape(βc[ind_nocons], 5,2,5)
βc  = permutedims(permutedims(βc, [1,3,2]), [2,1,3])


βct = (Xct.'*Xct)\Xct.'*z
ind_cons = N*P*collect(1:N) + collect(1:N)
ind_nocons = setdiff(collect(1:N*N*P+N), ind_cons)
μct  = βct[ind_cons]
αct  = βct[end]
βct  = reshape(βct[ind_nocons], 5,2,5)
βct  = permutedims(permutedims(βct, [1,3,2]), [2,1,3])


function IRFdt(A, α, shock; TT = 20)
    responses = zeros(TT, size(A)[2])
    responses[1,:] = shock
    responses[2,:] = A[:,:,1] * responses[1,:] + α
    for tt = 3:TT
        responses[tt,:] = A[:,:,1] * responses[tt-1,:] + A[:,:,2] * responses[tt-2,:] + α * (tt-1)
    end
    return(responses)
end

##----------------------------------------------------------------------------##
##----------------------------------------------------------------------------##
##----------------------------------------------------------------------------##
##--## ## ESTIMATE THE VAR
Aols,μols,Σols,resids         = VARols(2, datVAR; cons=false)
Aolsc,μolsc,Σolsc,residsc     = VARols(2, datVAR)
Aolst,μolst,Σolst,residst     = VARols(2, datVAR; cons=false, Z = collect(1:TT))
Aolsct,μolsct,Σolsct,residsct = VARols(2, datVAR; cons=true,  Z = collect(1:TT))
##--## 
##--## Pchol = chol(Σols)
responses_tols  = IRF(Aolst, μolst[:,1]*0, 20, [0, 0, 0, 0, 0.22]).' * 100
responses_ctols = IRF(Aolsct, μolsct[:,1]*0, 20, [0, 0, 0, 0, 0.22]).' * 100
##--## responses = IRFdt(βt, zeros(1,N), 20, [0, 0, 0, 0, 0.22]).' * 100
##--## responses = IRFdt(βt, 0*αt, [0, 0, 0, 0, 0.22]) * 100
responses = IRFdt(Aolsct, 0, [0, 0, 0, 0, 0.22]) * 100
##--## 
##--## 
plotIRF(responses[:,1], "Log Real GDP  Capita"                 , "output/IRF_Y_P")
plotIRF(responses[:,2], "Log Real Consumption"                 , "output/IRF_c_P")
plotIRF(responses[:,3], "Log Real Investment"                  , "output/IRF_I_P")
plotIRF(responses[:,4], "Trade Balance/GDP"                    , "output/IRF_TBY_P")
plotIRF(responses[:,5], "Commodity Price (Deviation from mean)", "output/IRF_P_P")
