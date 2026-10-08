"""Capture actual app motion on the dedicated QA simulator (no UI compositing)."""
import subprocess,time,signal,sys
from pathlib import Path
sim=sys.argv[1]
root=Path(__file__).resolve().parents[1]
out=root/'Deliverables'/'Revision-02'
out.mkdir(exist_ok=True)
mode=sys.argv[2] if len(sys.argv)>2 else 'discovery'
args=['--demo'] if mode=='discovery' else ['--pattern='+mode]
raw=root/'.build'/('revision-'+mode+'.mov')
subprocess.run(['xcrun','simctl','terminate',sim,'studio.fractal.lens'],capture_output=True)
record=subprocess.Popen(['xcrun','simctl','io',sim,'recordVideo','--codec=h264',str(raw)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
time.sleep(.4)
start=time.monotonic()
subprocess.run(['xcrun','simctl','launch',sim,'studio.fractal.lens',*args],check=True)
if mode=='discovery':
    for deadline,name in [(3.5,'05-photograph'),(8,'06-skeleton'),(12,'07-scale-dive'),(18,'04-scale-alignment'),(23,'08-replay'),(27,'09-alter'),(32,'10-collection')]:
        time.sleep(max(0,deadline-(time.monotonic()-start)))
        subprocess.run(['xcrun','simctl','io',sim,'screenshot',str(out/(name+'.png'))],capture_output=True)
    time.sleep(max(0,35-(time.monotonic()-start)))
else:
    time.sleep(13)
record.send_signal(signal.SIGINT)
record.communicate(timeout=30)
print('Recorded',raw)
