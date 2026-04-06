import re, statistics

# Membaca log file untuk MobileNet Dynamic
with open('perf_log_mobilenet_dynamic.txt', encoding='utf-8') as f:
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
print(f"=== HASIL ANALISIS MODEL MOBILENET (DYNAMIC RANGE) ===")
print(f"Total data points (sampel detik): {n}")
print(f"Durasi pengujian: ~{n} detik")
print()
print(f"=== FPS ===")
print(f"Min : {min(fps_list) if n > 0 else 0}")
print(f"Max : {max(fps_list) if n > 0 else 0}")
print(f"Avg : {sum(fps_list)/n:.2f}" if n > 0 else "Avg : 0.00")
print()
print(f"=== ML Kit Latency (ms) ===")
print(f"Avg : {sum(ml_list)/n:.2f}" if n > 0 else "Avg : 0.00")
print(f"Max : {max(ml_list) if n > 0 else 0}")
print()
print(f"=== TFLite Latency (ms) ===")
print(f"Min : {min(tf_list) if n > 0 else 0}")
print(f"Max : {max(tf_list) if n > 0 else 0}")
print(f"Avg : {sum(tf_list)/n:.2f}" if n > 0 else "Avg : 0.00")
print(f"Std : {statistics.stdev(tf_list) if n > 1 else 'N/A'}")
print()
print(f"=== Total Latency (ms) ===")
print(f"Avg : {sum(tot_list)/n:.2f}" if n > 0 else "Avg : 0.00")
print()

# Rolling window per 30 data (detik)
print("=== ANALISIS STABILITAS (ROLLING WINDOW 30 DETIK) ===")
for i in range(0, n-29, 30):
    wt = tot_list[i:i+30]
    wf = tf_list[i:i+30]
    wp = fps_list[i:i+30]
    w = i//30 + 1
    print(f"Window {w} (Detik {i+1}-{i+30}):")
    print(f"  Avg FPS         = {sum(wp)/len(wp):.1f}")
    print(f"  Avg TFLite Lat. = {sum(wf)/len(wf):.1f} ms")
    print(f"  Avg Total Lat.  = {sum(wt)/len(wt):.1f} ms")
