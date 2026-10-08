"""Record the real guided live-lens state sequence on a dedicated simulator."""
import subprocess,time,signal,sys
from pathlib import Path
sim=sys.argv[1]
root=Path(__file__).resolve().parents[1]
out=root/'Deliverables'/'Revision-03'
out.mkdir(exist_ok=True)
raw=root/'.build'/'live-lens.mov'
subprocess.run(['xcrun','simctl','terminate',sim,'studio.fractal.lens'],capture_output=True)
record=subprocess.Popen(['xcrun','simctl','io',sim,'recordVideo','--codec=h264',str(raw)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
time.sleep(.4)
start=time.monotonic()
subprocess.run(['xcrun','simctl','launch',sim,'studio.fractal.lens','--live-preview=windows'],check=True)
for deadline,name in [(1.7,'02-live-lens'),(4.5,'03-frozen-moment'),(6.8,'04-contour-reveal'),(11.5,'05-everyday-evidence')]:
    time.sleep(max(0,deadline-(time.monotonic()-start)))
    subprocess.run(['xcrun','simctl','io',sim,'screenshot',str(out/(name+'.png'))],capture_output=True)
time.sleep(max(0,14.5-(time.monotonic()-start)))
record.send_signal(signal.SIGINT)
record.communicate(timeout=30)
print('Recorded',raw)
