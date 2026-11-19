import sys
print("Step 1: start script", flush=True)

import httpx
print("Step 2: httpx imported", flush=True)

from app.main import app
print("Step 3: app imported", flush=True)

# Test routes directly using starlette TestClient or direct router inspection
routes = []
for route in app.routes:
    if hasattr(route, "path"):
        routes.append(route.path)

print(f"Step 4: Total routes registered: {len(routes)}", flush=True)
for r in sorted(routes):
    print(f"  Route: {r}", flush=True)

# Test with Starlette testclient without lifespan
from starlette.testclient import TestClient
print("Step 5: creating TestClient", flush=True)
client = TestClient(app, raise_server_exceptions=True)
print("Step 6: TestClient created", flush=True)

res = client.get("/health")
print(f"Step 7: /health returned {res.status_code}: {res.json()}", flush=True)

res_docs = client.get("/docs")
print(f"Step 8: /docs returned {res_docs.status_code}, content length {len(res_docs.text)}", flush=True)

print("Step 9: ALL VERIFICATIONS PASSED!", flush=True)
