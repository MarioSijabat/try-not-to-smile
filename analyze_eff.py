import re, statistics

with open('perf_log_efficientnet.txt', encoding='utf-8') as f:
    lines = [l for l in f.readlines() if '[PERF]' in l]

fps_list, ml_list, tf_list, tot_list = [], [], [], []

for l in lines:
    m = re.search(r'FPS:(\d+).*MLKit:(\d+)ms.*TFLite:(\d+)ms.*Total:(\d+)ms', l)
    if m:
        fps_list.append(int(m.group(1)))
        ml_list.append(int(m.group(2)))
        tf_list.append(int(m.group(3)))
        tot_list.append(int(m.group(4)))

n = len(fps_list)
print(f"=== DATA PENGUJIAN MODEL EFFICIENTNET ===")
print(f"Total data points (detik): {n}")
print(f"Durasi pengujian: ~{n} detik")
print()
print(f"=== FPS ===")
print(f"Min : {min(fps_list)}")
print(f"Max : {max(fps_list)}")
print(f"Avg : {sum(fps_list)/n:.2f}")
print(f"Std : {statistics.stdev(fps_list):.2f}")
print()
print(f"=== ML Kit Latency (ms) ===")
print(f"Min : {min(ml_list)}")
print(f"Max : {max(ml_list)}")
print(f"Avg : {sum(ml_list)/n:.2f}")
print(f"Std : {statistics.stdev(ml_list):.2f}")
print()
print(f"=== TFLite Latency (ms) ===")
print(f"Min : {min(tf_list)}")
print(f"Max : {max(tf_list)}")
print(f"Avg : {sum(tf_list)/n:.2f}")
print(f"Std : {statistics.stdev(tf_list):.2f}")
print()
print(f"=== Total Latency (ms) ===")
print(f"Min : {min(tot_list)}")
print(f"Max : {max(tot_list)}")
print(f"Avg : {sum(tot_list)/n:.2f}")
print(f"Std : {statistics.stdev(tot_list):.2f}")
print()

# Rolling window per 30 data
print("=== ROLLING WINDOW (per 30 detik) ===")
for i in range(0, n-29, 30):
    wt = tot_list[i:i+30]
    wm = ml_list[i:i+30]
    wf = tf_list[i:i+30]
    wp = fps_list[i:i+30]
    w = i//30 + 1
    print(f"Window {w} (s{i+1}-s{i+30}):")
    print(f"  FPS avg  = {sum(wp)/len(wp):.1f}")
    print(f"  MLKit    = avg {sum(wm)/len(wm):.1f}ms | min {min(wm)} | max {max(wm)} | range {max(wm)-min(wm)}")
    print(f"  TFLite   = avg {sum(wf)/len(wf):.1f}ms | min {min(wf)} | max {max(wf)} | range {max(wf)-min(wf)}")
    print(f"  Total    = avg {sum(wt)/len(wt):.1f}ms | min {min(wt)} | max {max(wt)} | range {max(wt)-min(wt)}")
