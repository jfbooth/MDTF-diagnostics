load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;***************************************************************************************************************************
;                   resource for public
;***************************************************************************************************************************
res = True

res@gsnFrame           = False
res@gsnDraw            = False
;res@vpHeightF          = 0.8
;res@vpWidthF           = 0.8

res@gsnLeftString              = ""
res@gsnRightString             = ""
res@gsnCenterString            = ""
res@tiXAxisString        = ""
res@tiYAxisString        = ""

;res@vpXF              = 0.15
;res@vpYF              = 0.95
;res@vpWidthF          = 0.6
;res@vpHeightF         = 0.6
;res@tmBorderThicknessF= 3
;res@tmXTMajorThicknessF=3
;res@tmXTMinorThicknessF=2
;res@tmXBMajorThicknessF=3
;res@tmXBMinorThicknessF=2
;res@tmYLMajorThicknessF=3
;res@tmYLMinorThicknessF=2
;res@tmYRMajorThicknessF=3
;res@tmYRMinorThicknessF=2
res@tmYROn             = False

res@tiXAxisString             = "Transport (Sv)"
res@tiYAxisString             = "Depth (m)"

res@trYMinF = 0 
res@trYMaxF = 5500
res@trYReverse = True

res@xyMarkLineMode   ="Lines"
res@xyDashPattern    = 0
res@xyLineThicknessF = 2.0

res@trYReverse                  = True
;res@gsnStringFontHeightF=0.028


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------------------------------------------------------------------------------------------- Enviromental variables
DIR_in0    = getenv("CLMREF")
DIR_in1    = getenv("WKDIR")
DIR_out    = getenv("WKDIR")
lat0       = stringtofloat(getenv("LAT0"))
models = str_split(getenv("MODELS"), " ,")
num_model=dimsizes(models)

lev_var = getenv("lev_var")
lat_var = getenv("lat_var")

if(lat0.ge.0)then
  res@gsnCenterString = "Latitude: "+tostring_with_format(lat0,"%4.1f")+"~S~o~N~N"
else  
  res@gsnCenterString = "Latitude: "+tostring_with_format(abs(lat0),"%4.1f")+"~S~o~N~S"
end if

ncs0="RAPID.sf26.clim.nc"

plot = new(num_model,graphic)
plot1 = new(1,graphic)
plot2 = new(1,graphic)

wks   = gsn_open_wks("png",DIR_out+"/sum_Q_lat0_z_plot")
if(num_model.le.20)then
  gsn_define_colormap(wks,"xbxu")
  colors=floattoint(fspan(2,21,num_model))
else
  gsn_define_colormap(wks,"amwg256")
  colors=floattoint(fspan(2,255,num_model))
end if
;print(""+dimsizes(colors))
orders=ispan(1,num_model+2,1)

;---------------------------------------------------------------------------------------------------- reference
nc = DIR_in0+ncs0
;print("Loading ... "+nc)
fin = addfile(nc,"r")
LEV  = fin->depth
REF  = dim_avg_n_Wrap(fin->stream_function_mar,1)
num_lev=dimsizes(LEV)
out=new((/num_model,num_lev/),"double",1e20)

;---------------------------------------------------------------------------------------------------- axis range
xmin=min(REF)
xmax=max(REF)
do mm=0,num_model-1
  model=models(mm)
  DIR_in=DIR_in1+"/MDTF_"+model+"/AMOC_3D_Structure/model/netCDF/"
  nc=model+".AMOC_T2B.clim.nc"
;  print("Loading ... "+nc)
  fin = addfile(DIR_in+nc,"r")
  lat = fin->$lat_var$
  jjj = minind(abs(lat-lat0))
  var = fin->moc(0,:,jjj,0)
  xmin=tointeger( min( (/min(var),xmin/) ) - 0.5)
  xmax=tointeger( max( (/max(var),xmax/) ) + 0.5)
  delete(var)
  delete(lat)
end do

dist = (xmax-xmin)*0.1
xmin = tointeger(xmin - dist - 0.5)
xmax = tointeger(xmax + dist + 0.5)
res@trXMinF = xmin
res@trXMaxF = xmax

;print(xmin+" "+xmax)
;---------------------------------------------------------------------------------------------------- plot
do mm=0,num_model-1
  model=models(mm)
  DIR_in=DIR_in1+"/MDTF_"+model+"/AMOC_3D_Structure/model/netCDF/"
  nc=model+".AMOC_T2B.clim.nc"
  fin = addfile(DIR_in+nc,"r")
  lat = fin->$lat_var$
  lev = fin->$lev_var$
  jjj = minind(abs(lat-lat0))
  var = fin->moc(0,:,jjj,0)
  out(mm,:)=linint1_n_Wrap(lev,var,False,LEV,0,0)
  res@xyLineColor = colors(mm)
  plot(mm) = gsn_csm_xy(wks,var,lev,res)
  delete(var)
  delete(lev)
  delete(lat)
end do

do mm=1,num_model-1
  overlay(plot(0),plot(mm))
end do

;---------------------------------------------------------------------------------------------------- plot model mean
MME=dim_avg_n_Wrap(out,0)
res@xyDashPattern = 1
res@xyLineColor = 1
res@xyLineThicknessF      = 5
plot1 = gsn_csm_xy (wks,MME,LEV,res)
overlay(plot(0),plot1)
delete(MME)
;---------------------------------------------------------------------------------------------------- plot reference
res@xyDashPattern = 0
res@xyLineColor = 1
res@xyLineThicknessF      = 5
plot2 = gsn_csm_xy (wks,REF,LEV,res)
overlay(plot(0),plot2)
delete(REF)

;---------------------------------------------------------------------------------------------------- legend
colorss=new(num_model+2,typeof(colors))
modelss=new(num_model+2,typeof(models))
dashess=orders
colorss(0:num_model-1)=(/colors/)
modelss(0:num_model-1)=(/models/)
dashess(0:num_model-1)=0
colorss(num_model)=1
modelss(num_model)="20-CMIP5 average"
dashess(num_model)=1
colorss(num_model+1)=1
modelss(num_model+1)="RAPID"
dashess(num_model+1)=0
;print(dashess)

lgres                    = True
lgres@lgLineColors       = colorss
lgres@lgDashIndexes      = dashess
lgres@lgBoxLinesOn       = False
lgres@lgPerimOn          = False
lgres@lgLineThicknessF   = 5
lgres@lgItemType         = "Lines"        ; show lines only (default)
lgres@lgLabelFontHeightF = 0.08           ; legend label font thickness
lgres@vpWidthF           = 0.12            ; width of legend (NDC)
lgres@vpHeightF          = 0.64           ; height of legend (NDC)
;lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lgres@lgMonoDashIndex    = False
lgres@lgItemOrder        = orders(::-1)-1
labels = modelss
nitems = dimsizes(labels)                 ; number of legend items

amres                  = True
amres@amJust           = "CenterCenter"  ; Use bottom right corner of box
amres@amParallelPosF   = 0.62            ; + left, - right
;amres@amOrthogonalPosF = 0.55            ; + up    - down
lbid = gsn_create_legend(wks,nitems,labels,lgres)
annoid = gsn_add_annotation(plot(0),lbid,amres)  ; add legend to plot
;====================================================================================================

;;;;;; Maximize output on the page and draw everything
pres=True
draw(plot(0))
frame(wks)