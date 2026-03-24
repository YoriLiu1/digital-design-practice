debImport "-f" "file.list" "+nologo"
debLoadSimResult \
           /home/yori/digital-design-practice/sim/async_fifo/async_fifo.fsdb
wvCreateWindow
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/async_fifo_tb"
wvGetSignalSetOptions -win $_nWave2 -input on
wvGetSignalSetSignalFilter -win $_nWave2 "*"
wvGetSignalSetOptions -win $_nWave2 -output on
wvGetSignalSetSignalFilter -win $_nWave2 "*"
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/async_fifo_tb/u_asyn_fifo/almost_empty} \
{/async_fifo_tb/u_asyn_fifo/almost_full} \
{/async_fifo_tb/u_asyn_fifo/data_in\[7:0\]} \
{/async_fifo_tb/u_asyn_fifo/data_out\[7:0\]} \
{/async_fifo_tb/u_asyn_fifo/rclk} \
{/async_fifo_tb/u_asyn_fifo/rd_en} \
{/async_fifo_tb/u_asyn_fifo/rempty} \
{/async_fifo_tb/u_asyn_fifo/rst_n} \
{/async_fifo_tb/u_asyn_fifo/wclk} \
{/async_fifo_tb/u_asyn_fifo/wfull} \
{/async_fifo_tb/u_asyn_fifo/wr_en} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 )} 
wvSetPosition -win $_nWave2 {("G1" 11)}
wvGetSignalClose -win $_nWave2
wvZoomIn -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomIn -win $_nWave2
debExit
