using PyPlot
##----------------------------------------------------------------------------##
##----------------------------------------------------------------------------##
##----------------------------------------------------------------------------##
function plotIRF(IRF, idx, shock, vname, fname, ;units="Percent", CIlow = [], CIhigh=[],Clevel=95,TITLE="")
    T = size(IRF)[3]    
    f = figure(figsize = (5,4))
    plot(1:T, repmat([0],T,1), color = "black", linewidth = 1)

    LINESTYLES = repmat(["-", "--", ":"], 1,10)
    COLORS = repmat(["black", "gray"], 1,10)

    y = IRF[idx, shock, :]'
    
    if length(size(y)) > 1
        for ss in 1:size(y)[2]
            plot(1:T, y[:,ss], linewidth = 2, label=vname[ss],
                 linestyle=LINESTYLES[ss], color=COLORS[ss])            
        end
    else
        plot(1:T, y, linewidth = 2, label=vname)
        TITLE = vname
    end


    if length(CIlow)>0
        fill_between(1:T, CIlow, CIhigh, facecolor="gray",
                     alpha=0.5,label=string(Clevel, "% CI"))
    end
    xlim(1,T)
    xlabel("t")
    title(TITLE)
    ylabel(units)
    legend()
    savefig(string(fname,".pdf"))
    close(f)
    close()
end
