"""Capture the app's real 30-second discovery on a dedicated booted simulator."""
import subprocess,time,signal,sys
from pathlib import Path
sim=sys.argv[1]
root=Path(__file__).resolve().parents[1]
out=root/'Deliverables'
subprocess.run(['xcrun','simctl','terminate',sim,'studio.fractal.lens'],capture_output=True)
raw=out/'discovery-capture.mov'
record=subprocess.Popen(['xcrun','simctl','io',sim,'recordVideo','--codec=h264',str(raw)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
time.sleep(.4)
start=time.monotonic()
subprocess.run(['xcrun','simctl','launch',sim,'studio.fractal.lens','--demo'],check=True)
# Snapshots are captured from the actual running sequence, not composited screens.
for deadline,name in [(3.5,'03-photograph'),(8,'04-skeleton'),(12,'05-scale-dive'),(18,'06-self-similarity'),(23,'08-replay'),(27,'09-alter'),(32,'10-collection')]:
    time.sleep(max(0,deadline-(time.monotonic()-start)))
    subprocess.run(['xcrun','simctl','io',sim,'screenshot',str(out/(name+'.png'))],capture_output=True)
time.sleep(max(0,36-(time.monotonic()-start)))
record.send_signal(signal.SIGINT)
record.communicate(timeout=30)
print('Recorded',raw)
