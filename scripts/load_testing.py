import json
import requests
import threading
from queue import Queue
from time import time

# -------------------------------
# Interactive Inputs
# -------------------------------

URL = input("Target URL: ")
METHOD = input("Method (GET/POST/PUT/DELETE): ").upper()
raw_payload = input("JSON Payload (or leave empty): ")

if raw_payload.strip():
    try:
        PAYLOAD = json.loads(raw_payload)
    except Exception as e:
        print("Invalid JSON payload! Error:", e)
        exit(1)
else:
    PAYLOAD = None

HEADERS = {"Content-Type": "application/json"}

NUM_THREADS = int(input("Number of Threads: "))
NUM_REQUESTS = int(input("Number of Requests: "))

# -------------------------------
# Worker Thread Function
# -------------------------------

def worker(queue, results):
    while not queue.empty():
        queue.get()
        try:
            start = time()

            if METHOD == "GET":
                response = requests.get(URL, headers=HEADERS, timeout=10)
            else:
                response = requests.request(
                    METHOD,
                    URL,
                    json=PAYLOAD,
                    headers=HEADERS,
                    timeout=10
                )

            duration = round(time() - start, 4)
            results.append({
                "status": response.status_code,
                "duration": duration,
                "content": response.text[:300]
            })

            print(f"[{response.status_code}] {duration}s -> {response.text[:80]}")

        except Exception as e:
            results.append({
                "status": "ERROR",
                "duration": 0,
                "content": str(e)
            })
            print(f"[ERROR] {e}")

        finally:
            queue.task_done()


# -------------------------------
# Main Test Function
# -------------------------------

def run_test():
    print(f"\n🚀 Launching load test: {NUM_REQUESTS} requests using {NUM_THREADS} threads...\n")

    q = Queue()
    results = []

    for _ in range(NUM_REQUESTS):
        q.put(1)

    threads = []
    for _ in range(NUM_THREADS):
        t = threading.Thread(target=worker, args=(q, results))
        t.daemon = True
        t.start()
        threads.append(t)

    q.join()

    print("\n📌 Load Test Completed!")
    print(f"Total Requests: {len(results)}")
    success = len([r for r in results if r['status'] != 'ERROR'])
    print(f"Successful: {success}")
    print(f"Errors: {len(results) - success}")

    return results


# -------------------------------
# Execute
# -------------------------------

if __name__ == "__main__":
    run_test()
